// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IBlast} from "./Interfaces/IBlast.sol";
import "./Interfaces/IERC20Rebasing.sol";
import "./utils/Structs.sol";
import "./Interfaces/IErrors.sol";
import "./Interfaces/IGasLot.sol";

// To use circuit-breaker pattern from oz-contracts, can use:
//  import "@openzeppelin/contracts/security/Pausable.sol";
//  (As a tradeoff, currently I decided to just implement my simple circuit-breaker for gas efficiency)
// Todo: import {CampaignTypes} from "./CampaignTypes.sol";

/// @title The crowdfunding platform
/// @author Bahador Ghadamkheir
/// @dev This is a sample crowdfunding smart contract.
/// @notice As this contract is not audited, use at your own risk!
contract BaseCampaign is Ownable, IErrors {
    using SafeMath for uint256;

    IBlast public constant BLAST =
        IBlast(0x4300000000000000000000000000000000000002);
    IERC20Rebasing public constant USDB =
        IERC20Rebasing(0x4200000000000000000000000000000000000022);
    IERC20Rebasing public constant WETH =
        IERC20Rebasing(0x4200000000000000000000000000000000000023);
    address public immutable platformOwner;

    uint16 public constant dYieldShare = 8_000;
    uint16 public constant dGasShare = 8_000;
    // defining tax of the platform
    uint8 public constant platformTax = 100;
    // avtivity status of the contract
    bool public emergencyMode; // default: false
    // holding number of all campaigns
    uint24 public numberOfCampaigns;

    // a mapppig to hold campaign's data
    mapping(uint256 => Campaign) public campaigns;

    // Will be emitted when a main functionality executed
    // (such as: creating/deleting/updating capaigns, and etc.)
    event Action(
        uint256 id,
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    // Will be emitted in case of changing activity status of the contract
    event ContractStateChanged(bool State);

    // To have an scape way when something bad happened in contract
    modifier notInEmergency() {
        require(!emergencyMode);
        _;
    }

    // To have an scape way when something bad happened in contract
    modifier onlyInEmergency() {
        require(emergencyMode);
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner);
        _;
    }

    // Preventing entering null values as campaign details
    modifier notNull(
        string memory title,
        string memory description,
        uint256 target,
        uint256 deadline,
        string memory image
    ) {
        _nullChecker(title, description, target, deadline, image);
        _;
    }

    // Preventing unauthorized entity execute specific function
    modifier privilageEntity(uint _id) {
        _privilagedEntity(_id);
        _;
    }

    /// @param _gov the governer address of the yield and gas
    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        address _gov,
        address _pOwner
    ) {
        _createCampaign(
            _owner,
            _title,
            _description,
            _target,
            _deadline,
            _image
        );
        platformOwner = _pOwner;
        BLAST.configureClaimableYield();
        BLAST.configureClaimableGas();
        BLAST.configureGovernor(_gov);
    }

    /** @notice Create a fundraising campaign
     *  @param _owner creator of the fundraising campaign
     *  @param _title title of the fundraising campaign
     *  @param _description description of the fundraising campaign
     *  @param _target desired ETH target amount of the fundraising campaign(based on wei)
     *  @param _deadline deadline of the fundraising campaign
     *  @param _image image address of the fundraising campaign
     */
    function _createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    )
        internal
        notNull(_title, _description, _target, _deadline, _image)
        notInEmergency /*returns (uint256)*/
    {
        require(block.timestamp < _deadline, "Deadline must be in the future");
        Campaign storage campaign = campaigns[numberOfCampaigns];
        // numberOfCampaigns++;

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.payedOut = false;

        emit Action(
            numberOfCampaigns,
            "Campaign Created",
            msg.sender,
            block.timestamp
        );

        // return numberOfCampaigns - 1;
    }

    /** @notice Update a fundraising campaign
     *  @param _id campign id
     *  @param _title new title of the fundraising campaign
     *  @param _description new description of the fundraising campaign
     *  @param _target new desired ETH target amount of the fundraising campaign(based on wei)
     *  @param _deadline new deadline of the fundraising campaign
     *  @param _image new image address of the fundraising campaign
     *  @return status of campaign update request
     */
    function updateCampaign(
        uint256 _id,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    )
        external
        privilageEntity(_id)
        notNull(_title, _description, _target, _deadline, _image)
        notInEmergency
        returns (bool)
    {
        require(block.timestamp < _deadline, "Deadline must be in the future");

        // Making a pointer for a campaign
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner > address(0), "No campaign exist with this ID");
        require(
            campaign.amountCollected == 0,
            "Update error: amount collected"
        );

        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.payedOut = false;

        emit Action(0, "Campaign Updated", msg.sender, block.timestamp);
        return true;
    }

    /// @notice Donate to an specific fundraising campaign
    /// @param _id campaign id
    function donateToCampaign(uint256 _id) external payable notInEmergency {
        if (msg.value == 0 wei)
            revert LowEtherAmount({minAmount: 1 wei, payedAmount: msg.value});
        Campaign storage campaign = campaigns[_id];
        if (campaigns[_id].payedOut == true) revert("Funds withdrawed before");
        require(campaign.owner > address(0), "No campaign exist with this ID");
        if (campaign.deadline < block.timestamp) {
            revert DeadLine({
                campaingDeadline: campaigns[_id].deadline,
                requestTime: block.timestamp
            });
        }
        uint256 amount = msg.value;
        if (campaign.amountCollected > campaign.amountCollected.add(amount))
            revert("Target amount has reached");
        campaign.amountCollected = campaign.amountCollected.add(amount);

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        emit Action(0, "Donation To The Campaign", msg.sender, block.timestamp);
    }

    /// @notice Transfering raised funds to the campaign team
    /// @param _id campaign id
    /// @return true, if payout process get completely done
    function payOutToCampaignTeam(
        uint256 _id
    ) external privilageEntity(_id) notInEmergency returns (bool) {
        // this line will avoid re-entrancy attack
        if (campaigns[_id].payedOut == true) revert("Funds withdrawed before");
        // if (msg.sender != address(owner())) {
        if (campaigns[_id].deadline > block.timestamp) {
            revert DeadLine({
                campaingDeadline: campaigns[_id].deadline,
                requestTime: block.timestamp
            });
        }
        // }

        campaigns[_id].payedOut = true;
        (uint256 raisedAmount, uint256 taxAmount) = _calculateTax(_id);
        _payTo(campaigns[_id].owner, (raisedAmount - taxAmount));
        _payPlatformFee(taxAmount);
        emit Action(0, "Funds Withdrawal", msg.sender, block.timestamp);
        return true;
    }

    /// @notice Paying platform fee
    /// @param _taxAmount tax amount to transfer into platform owner account
    function _payPlatformFee(uint256 _taxAmount) internal {
        _payTo(owner(), _taxAmount);
    }

    /// @notice Deleting a specific fundraising campaign
    /// @param _id campaign id
    /// @return true, if deleting be correctly done
    function deleteCampaign(
        uint256 _id
    ) external privilageEntity(_id) notInEmergency returns (bool) {
        // to check if a capmpaign with specific id exists.
        require(
            campaigns[_id].owner > address(0),
            "No campaign exist with this ID"
        );
        if (campaigns[_id].amountCollected > 0 wei) {
            _refundDonators(0);
        }
        delete campaigns[_id];

        emit Action(_id, "Campaign Deleted", msg.sender, block.timestamp);

        // numberOfCampaigns -= 1;
        return true;
    }

    /// @notice Showing donators of a specific campaign
    /// @param _id campaign id
    /// @return donator's addresses
    /// @return donator's funded amount
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getDonatorsCount(uint256 _id) public view returns (uint) {
        return campaigns[_id].donations.length;
    }

    // /// @notice Updating platform tax
    // /// @param _platformTax new platform tax
    // function changeTax(uint8 _platformTax) external onlyPlatformOwner {
    //     platformTax = _platformTax;
    // }

    /// @notice Halting fundraising of a specific campaign
    /// @param _id campaign id
    function haltCampaign(uint256 _id) external onlyPlatformOwner {
        campaigns[_id].deadline = block.timestamp;

        emit Action(0, "Campaign halted", msg.sender, block.timestamp);
    }

    /** @notice Showing all campaigns data
     *  @dev todo: making slicing for pagination,
     *  @dev       to reduce the chance of reverting(exceeding block gas limit) in case of big number of campaigns.
     *  @dev           getCampaigns(uint256 startIndex, uint256 endIndex)
     *  @return campaigns data
     */
    function getCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    /// @notice Changing activity status of the contract
    /// @dev implemented mainly for any unintended situation which risks campaigns funds
    function changeContractState() external onlyPlatformOwner {
        emergencyMode = !emergencyMode;

        emit ContractStateChanged(emergencyMode);
    }

    /// @notice Withdrawing funds and refunding to donators, in case of an emergency situation(such as bugs, hacks, etc)
    /// @param _startId id of the first campaign to refund
    /// @param _endId id of the end campaign to refund
    function withdrawFunds(
        uint256 _startId,
        uint256 _endId
    ) external onlyPlatformOwner onlyInEmergency {
        for (uint i = _startId; i <= _endId; i++) {
            _refundDonators(_startId, _endId);
        }
    }

    /// @notice Making refund to donators of a specific campaign
    /// @param _id campgin id
    function _refundDonators(uint _id) internal {
        uint256 donationAmount;
        Campaign storage campaign = campaigns[_id];
        for (uint i; i < campaign.donators.length; i++) {
            donationAmount = campaign.donations[i];
            campaign.donations[i] = 0;
            _payTo(campaign.donators[i], donationAmount);
            // campaign.donations[i] = 0;
        }
        campaign.amountCollected = 0;
    }

    /// @notice Making refund to donators of specific campaigns range
    /// @param _idFrom campgin id from
    /// @param _idTo campgin id to
    function _refundDonators(uint256 _idFrom, uint256 _idTo) internal {
        require(_idFrom < _idTo, "Invalid id range");
        require(
            campaigns[_idTo].owner > address(0),
            "No campaign exist with this ID"
        );
        uint256 donationAmount;
        for (uint i = _idFrom; i < _idTo; i++) {
            Campaign storage campaign = campaigns[i];
            uint256 campaignDonators = campaign.donators.length;
            if (campaignDonators > 0) {
                for (uint j = 0; j < campaignDonators; j++) {
                    donationAmount = campaign.donations[j];
                    campaign.donations[j] = 0;
                    _payTo(campaign.donators[j], donationAmount);
                    // campaign.donations[j] = 0;
                }
                campaign.amountCollected = 0;
            }
        }
    }

    /// @notice Calculating the tax amount
    /// @param _id campaign id
    /// @return total funded amount of specific campaign
    /// @return tax amount of funded amount of specific campaign
    function _calculateTax(uint256 _id) internal view returns (uint, uint) {
        uint raised = campaigns[_id].amountCollected;
        uint tax = (raised * platformTax) / 10_000;
        return (raised, tax);
    }

    /// @notice Paying stakeholders of the campaign(campaign creator & platform owner)
    /// @param to recipient of the raised amount
    /// @param amount raised amount
    function _payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "PayTo failed");
        bool yClaimstat = yieldDistribution();
        require(yClaimstat == true, "Yield claim failed");
        return true;
    }

    /// @notice Calculating donator's share from the generated yields of the campaign
    /// @return Campaign's donators array of EOA addresses
    /// @return Campaign's donators array of share per EOA address
    function _calculateYieldShare()
        internal
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 dCount = getDonatorsCount(0);
        uint256 raised = campaigns[0].amountCollected;
        uint256 tClaimableYieldAmt = claimableYeildAmt();
        uint256[] memory dAmounts = new uint256[](dCount);
        address[] memory dAddresses = new address[](dCount);
        uint256[] memory dshares = new uint256[](dCount);

        for (uint i; i < dCount; i++) {
            dAddresses[i] = campaigns[0].donators[i];
            dAmounts[i] = campaigns[0].donations[i];
            dshares[i] =
                (dAmounts[i] / raised) *
                ((tClaimableYieldAmt * dYieldShare) / 10_000);
        }

        return (dAddresses, dshares);
    }

    /// @notice Getting campaign's claimable yield amount
    /// @return campaign's claimable yield amount
    function claimableYeildAmt() public view returns (uint256) {
        return BLAST.readClaimableYield(address(this));
    }

    /// @notice distributing generated yields to donators of the campaign
    function yieldDistribution() internal returns (bool) {
        (
            address[] memory dAddrs,
            uint256[] memory dShare
        ) = _calculateYieldShare();
        for (uint i; i < dShare.length; i++) {
            BLAST.claimYield(address(this), dAddrs[i], dShare[i]);
        }

        return true;
    }

    /// @notice WIthdrawing remaining yields in the campaign,
    ///         can be here as long as the platform owner,
    ///         wants to generate more yields
    function withdrawRemainingYield() public onlyPlatformOwner {
        require(
            block.timestamp > campaigns[0].deadline,
            "yield withdrawal not opened yet"
        );
        BLAST.claimAllYield(address(this), platformOwner);
    }

    /// @notice Depositing gas fees spent by donators into gasLot contract
    /// @param gasLot gasLot contract address
    function sendPlatformGas(address gasLot) external onlyPlatformOwner {
        require(
            block.timestamp >= campaigns[0].deadline + 30 days,
            "Claiming gas not opened yet"
        );
        BLAST.claimAllGas(address(this), gasLot);
    }

    /// @notice Drawing happy gasLot winners
    /// @param gasLot Address of the gasLot contract
    function grantLottoGas(address gasLot) external onlyPlatformOwner {
        Campaign memory theCampaign = campaigns[0];
        require(
            block.timestamp >= theCampaign.deadline + 30 days,
            "Claiming gas not opened yet"
        );
        address[] memory campDonators = new address[](
            theCampaign.donators.length
        );
        IGasLot(gasLot).dropToHappyWinners(campDonators);
    }

    /** @notice Preventing entering null values as campaign details
     *  @param _title title of the fundraising campaign
     *  @param _description description of the fundraising campaign
     *  @param _target desired ETH target amount of the fundraising campaign(based on wei)
     *  @param _deadline deadline of the fundraising campaign
     *  @param _image image address of the fundraising campaign
     */
    function _nullChecker(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) internal pure {
        require(
            (bytes(_title).length > 0 &&
                bytes(_description).length > 0 &&
                _target > 0 &&
                _deadline > 0 &&
                bytes(_image).length > 0),
            "Null value not acceptable"
        );
    }

    /// @notice Preventing unauthorized entity to execute specific function
    /// @param _id campaign id
    function _privilagedEntity(uint256 _id) internal view {
        Campaign memory theCOwner = campaigns[_id];
        require(
            msg.sender == theCOwner.owner || msg.sender == owner(),
            "Unauthorized Entity"
        );
    }
}

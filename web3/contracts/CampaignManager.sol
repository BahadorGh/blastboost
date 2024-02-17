// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseCampaign.sol";
import "./utils/Structs.sol";
import {IBlast} from "./Interfaces/IBlast.sol";
import {ICampaign} from "./Interfaces/ICampaign.sol";

contract CampaignManager is Ownable {
    uint256 campId;
    address public immutable platformOwner = _msgSender();
    BaseCampaign[] public campaigns;
    mapping(address campAddress => uint campId) theCampaign;
    mapping(uint campId => address campAddress) cIdToCAddress;
    // a mapppig to hold campaign's data
    mapping(uint => Campaign) public allTheCampaigns;

    event CampaignGenerated(address CampaignAddress);

    // Preventing unauthorized entity execute specific function
    modifier privilageEntity(uint _id) {
        _privilagedEntity(_id);
        _;
    }

    /// @notice Generating campaign
    /// @param _owner Address of the campaign's owner
    /// @param _title Campaign's title
    /// @param _description Campaign's description
    /// @param _target Campaign's fundraising target
    /// @param _deadline Campaign's fundraising latest time
    /// @param _image Campaign's main image address
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) external {
        BaseCampaign newCampaign = new BaseCampaign(
            _owner,
            _title,
            _description,
            _target,
            _deadline,
            _image,
            address(this),
            platformOwner
        );
        campaigns.push(newCampaign);
        cIdToCAddress[campId] = address(newCampaign);
        theCampaign[address(newCampaign)] = campId;
        // allTheCampaigns[address(newCampaign)] = Campaign({
        //     owner: _owner,
        //     payedOut: false,
        //     title: _title,
        //     description: _description,
        //     target: _target,
        //     deadline: _deadline,
        //     amountCollected: 0,
        //     image: _image,
        //     donators: new address[](0),
        //     donations: new uint[](0)
        // });
        campId++;

        emit CampaignGenerated(address(newCampaign));
    }

    /// @notice Showing the campaigns data
    /// @param start Id of the start campaign
    /// @param end Id of the end campaign
    /// @return campaign's data
    function getCampaigns(
        uint256 start,
        uint256 end
    ) external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](end - start);
        for (uint i = start; i < end; i++) {
            allCampaigns[i] = getCampaignsData(i);
        }
        return allCampaigns;
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campId);
        for (uint i = 0; i < campId; i++) {
            allCampaigns[i] = getCampaignsData(i);
        }
        return allCampaigns;
    }

    /// @notice Getting campaign's data
    /// @param _id Campaign's id
    /// @return campaign's data
    function getCampaignsData(
        uint256 _id
    ) internal view returns (Campaign memory) {
        return ICampaign(cIdToCAddress[_id]).campaigns(0);
    }

    /// @notice Doanting to a specific campaign
    /// @param _id Campaign's id to donate
    function donateToCampaign(uint256 _id) external payable {
        (bool success, ) = payable(cIdToCAddress[_id]).call{value: msg.value}(
            abi.encodeWithSignature("donateToCampaign(uint256)", 0)
        );
        require(success, "Donating failed");
    }

    /// @notice Updating a campaign
    /// @param _id Campaign's id
    /// @param _title Campaign's title
    /// @param _description Campaign's description
    /// @param _target Campaign's fundraising target
    /// @param _deadline Campaign's fundraising deadline
    /// @param _image Campaign's main image
    function updateCampaign(
        uint256 _id,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) external privilageEntity(_id) returns (bool) {
        ICampaign(cIdToCAddress[_id]).updateCampaign(
            _id,
            _title,
            _description,
            _target,
            _deadline,
            _image
        );
        return true;
    }

    /// @notice Deleting a specific campaign
    /// @param _id Campaign's id
    function deleteCampaign(
        uint256 _id
    ) external privilageEntity(_id) returns (bool) {
        return ICampaign(cIdToCAddress[_id]).deleteCampaign(0);
    }

    /// @notice Paying raised funds to the campaign's team
    /// @param _id Campaign's id
    function payOutToCampaignTeam(
        uint256 _id
    ) external privilageEntity(_id) returns (bool) {
        ICampaign(cIdToCAddress[_id]).payOutToCampaignTeam(0);
        return true;
    }

    /// @notice Getting a specific campaign's donators
    /// @param _id Campaign's id
    /// @return Address of the campaign's donators
    /// @return Donation amount of the campaign's donators
    function getCampaignDonators(
        uint256 _id
    ) public view returns (address[] memory, uint[] memory) {
        return ICampaign(cIdToCAddress[_id]).getDonators(0);
    }

    /// @notice Getting campaigns count
    function getCampaignsCount() internal view returns (uint256) {
        return campaigns.length;
    }

    /// @notice Preventing unauthorized entity to execute specific function
    /// @param _id campaign id
    function _privilagedEntity(uint256 _id) internal view {
        Campaign memory theCOwner = ICampaign(cIdToCAddress[_id]).campaigns(0);
        require(
            msg.sender == theCOwner.owner || msg.sender == owner(),
            "Unauthorized Entity"
        );
    }

    /// @notice Claiming generated yields
    /// @param campaignAddress Specific campaign's address
    function claimableYeildAmt(
        address campaignAddress
    ) external returns (uint256) {
        uint theCampId = theCampaign[campaignAddress];
        return ICampaign(cIdToCAddress[theCampId]).claimableYeildAmt();
    }

    /// @notice Withdrawing remaining yileds of a specific campaign
    /// @param campaignAddress Specific campaign's address
    function withdrawRremainingYield(
        address campaignAddress
    ) external onlyOwner {
        uint theCampId = theCampaign[campaignAddress];
        ICampaign(cIdToCAddress[theCampId]).withdrawRemainingYield();
    }
}

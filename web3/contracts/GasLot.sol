// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// import "@openzeppelin/contracts/access/Ownable.sol";
import {IBlast} from "./Interfaces/IBlast.sol";
import "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

library Errors {
    error IncorrectSender();

    error InsufficientFee();
}

contract GasLot {
    IBlast public constant BLAST =
        IBlast(0x4300000000000000000000000000000000000002);
    IEntropy constant entropy =
        IEntropy(0x98046Bd286715D3B0BC227Dd7a956b83D8978603);
    address constant entropyProvider =
        0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344;

    uint64 round = 1;
    address public gasGoverner;
    struct Round {
        address[] candidates;
        address[] winners;
        uint256 potAmt;
        address owner;
    }

    mapping(uint64 => address) private requestedRands;
    mapping(uint roundId => Round) public theCandidates;

    event GasDeposited(uint256 GasAmount);
    event RandRequest(uint64 sequenceNumber);
    event Winners(address[] WinningAddrs, uint Round);
    event GasDistributed(address[] Winners, uint Round);

    constructor(address _gov) {
        gasGoverner = _gov;
        BLAST.configureClaimableGas();
        BLAST.configureGovernor(_gov);
    }

    /// @notice generating random number using PYTH oracle
    /// @param randNum constructing a random element for user commitment
    /// @param donatorsCount total number of the round's contributers
    function generateHappyNumber(
        uint256 randNum,
        uint256 donatorsCount
    ) public payable returns (uint256) {
        uint256 fee = entropy.getFee(entropyProvider);
        if (msg.value < fee) {
            revert Errors.InsufficientFee();
        }
        uint64 sequenceNumber = entropy.request{value: fee}(
            entropyProvider,
            entropy.constructUserCommitment(bytes32(randNum)),
            true
        );
        requestedRands[sequenceNumber] = msg.sender;

        // limiting the generated random number, based on the total contributers count
        uint gRandom = uint(keccak256(abi.encodePacked(sequenceNumber))) %
            donatorsCount;

        emit RandRequest(sequenceNumber);

        return (gRandom);
    }

    /// @notice Drawing the round's winners
    /// @param donators wallet address of the round's contributers
    function drawHappyWinners(
        address[] calldata donators
    ) internal returns (address[] memory) {
        theCandidates[round].candidates = donators;
        uint256[] memory winningNums = new uint256[](3);
        address[] memory winners = new address[](3);
        for (uint i; i < winningNums.length; i++) {
            (winningNums[i]) = generateHappyNumber(
                i * donators.length,
                donators.length
            );
            winners[i] = donators[winningNums[i]];
        }
        emit Winners(winners, round);
        theCandidates[round].winners = winners;
        round++;
        return winners;
    }

    /// @notice Distributing spent gas fees on the platform to the winners
    ///         1st place winner: 50% of total round's gas fee
    ///         2nd place winner: 25% of total round's gas fee
    ///         3rd place winner: 15% of total round's gas fee
    ///         platform(wShares[3]) 15% of total round's gas fee,
    ///             which is the platfrom income from gas fees
    /// @param winners address of the round winners
    function gasDistribution(address[] memory winners) internal returns (bool) {
        (uint ethSeconds, uint ethBalance, , ) = BLAST.readGasParams(
            address(this)
        );
        uint256[] memory wShares = new uint256[](4);
        uint256[] memory wSecShares = new uint256[](4);
        wShares[0] = (ethBalance / 100) * 50;
        wShares[1] = (ethBalance / 100) * 25;
        wShares[2] = (ethBalance / 100) * 15;
        wShares[3] = (ethBalance / 100) * 10;
        wSecShares[0] = (ethSeconds / 100) * 50;
        wSecShares[1] = (ethSeconds / 100) * 25;
        wSecShares[2] = (ethSeconds / 100) * 15;
        wSecShares[3] = (ethSeconds / 100) * 10;
        for (uint i; i < winners.length; i++) {
            BLAST.claimGas(
                address(this),
                winners[i],
                wShares[i],
                wSecShares[i]
            );
        }
        return true;
    }

    function dropToHappyWinners(address[] calldata donators) public {
        require(msg.sender == gasGoverner, "You are not the governer");
        address[] memory theWinners = drawHappyWinners(donators);
        gasDistribution(theWinners);

        emit GasDistributed(theWinners, round);
    }

    receive() external payable {
        theCandidates[round].potAmt = msg.value;

        emit GasDeposited(msg.value);
    }
}

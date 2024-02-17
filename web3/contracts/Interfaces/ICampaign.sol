// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/Structs.sol";

interface ICampaign {
    function campaigns(uint256 _id) external view returns (Campaign memory);

    function getDonators(
        uint256 _id
    ) external view returns (address[] memory, uint256[] memory);

    function getDonatorsCount(uint256 _id) external view returns (uint);

    function deleteCampaign(uint256 _id) external returns (bool);

    function updateCampaign(
        uint256 _id,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) external returns (bool);

    function payOutToCampaignTeam(uint256 _id) external returns (bool);

    function claimableYeildAmt() external returns (uint256);

    function withdrawRemainingYield() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface ISpoilerTreasury {
    function setwithdrawActive(bool _activate) external;
    function depositToken(address _token, uint256 _amount) external;
    function withdrawToken(address _token, address _to, uint256 _amount) external;
}
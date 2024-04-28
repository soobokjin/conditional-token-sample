// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISpoilerPoint is IERC20Metadata {
  function backedToken() external view returns (address);

  function issuePointTo(address _to, uint256 _amount) external;
  function burnPointFrom(address _from, uint256 _amount) external;
}
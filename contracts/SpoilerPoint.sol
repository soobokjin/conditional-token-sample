// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable}  from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ISpoilerTreasury} from "./interfaces/ISpoilerTreasury.sol";


contract SpoilerPoint is ERC20("Spoiler Point", "SP"), Ownable {
    using SafeERC20 for IERC20;

    /// EVENTS ///
    event ApprovedIssuerAdded(address issuer);
    event ApprovedIssuerRemoved(address issuer);
    event PointIssue(address to, uint256 amount);
    event PointBurn(address from, uint256 amount);

    /// STATE VARIABLE ///

    IERC20Metadata public backedToken;
    ISpoilerTreasury public immutable treasury;

    mapping(address => bool) public  approvedTokenIssuer;

    modifier onlyApprovedTokenIssuer() {
      require(approvedTokenIssuer[_msgSender()] == true, "SpoilerPoint: No authority");
      _;
    }

    constructor(IERC20Metadata _backedToken, address _treasury) Ownable(msg.sender) {
      backedToken = _backedToken;
      treasury = ISpoilerTreasury(_treasury);

      IERC20(_backedToken).approve(_treasury, type(uint256).max);
    }

    function decimals() public view override returns (uint8) {
        return backedToken.decimals();
    }
    
    function addApprovedTokenIssuer(address _issuer) external onlyOwner {
        approvedTokenIssuer[_issuer] = true;

        emit ApprovedIssuerAdded(_issuer);
    }

    function removeApprovedTokenIssuer(address _issuer) external onlyOwner {
        approvedTokenIssuer[_issuer] = false;
        emit ApprovedIssuerRemoved(_issuer);
    }

    function issuePointTo(address _to, uint256 _amount) public onlyApprovedTokenIssuer {
        backedToken.transferFrom(_to, address(this), _amount);
        treasury.depositToken(address(backedToken), _amount);

        _mint(_to, _amount);

        emit PointIssue(_to, _amount);
    }

    function burnPointFrom(address _from, uint256 _amount) public onlyApprovedTokenIssuer {
        _burn(_from, _amount);

        treasury.withdrawToken(address(backedToken), _from, _amount);

        emit PointBurn(_from, _amount);
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner(){
        IERC20(_token).safeTransfer(_to, _amount);
    }
}

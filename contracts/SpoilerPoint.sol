// SPDX-License-Identifier: GPL-3.0

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable}  from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**

only mint & burn approve user can mint whenever requested.

decmial 

active Redeem

 */
contract SpoilerPoint is ERC20("Spoiler Point", "SP"), Ownable {
    /// EVENTS ///
    event ApprovedIssuerAdded(address issuer);
    event ApprovedIssuerRemoved(address issuer);
    event PointIssue(address to, uint256 amount);
    event PointBurn(address from, uint256 amount);

    /// STATE VARIABLE ///

    IERC20Metadata public backedToken;
    mapping(address => bool) public  approvedTokenIssuer;
    bool public redeemActive;

    modifier onlyApprovedTokenIssuer() {
      require(approvedTokenIssuer[msg.sender] == true, "SpoilerPoint: No authority");
      _;
    }

    modifier redeemActivated() {
      require(redeemActive == true, "SpoilerPoint: Redeem is not activated");
      _;
    }

    constructor(IERC20Metadata _backedToken) {
      backedToken = _backedToken;
    }

    function decimals() public view override returns (uint8) {
        return backedToken.decimals();
    }

    function setRedeemActive(bool _activate) external onlyOwner {
        redeemActive = _activate;
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

        _mint(_to, _amount);

        emit PointIssue(_to, _amount);
    }

    function burnPointFrom(address _from, uint256 _amount) public onlyApprovedTokenIssuer {
        backedToken.transfer(_from, value);
        
        _burn(_from, _share);

        emit PointBurn(_from, _amount);
    }
}

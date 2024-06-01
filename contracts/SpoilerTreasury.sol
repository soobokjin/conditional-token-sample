// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Ownable}  from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";


contract SpoilerTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) public  approvedTokenDepositor;
    // Redeeemer -> token -> balance
    mapping(address => mapping(address => uint256)) public depositorTokenBalance;
    bool public withdrawActive;

    event Deposit(address indexed token, address indexed from, uint256 amount);
    event Withdraw(address indexed token, address indexed from, address indexed to, uint256 amount);
    
    constructor() Ownable(msg.sender) {
        withdrawActive = false;
    }

    modifier withdrawActivated() {
      require(withdrawActive == true, "SpoilerPoint: Redeem is not activated");
      _;
    }

    function addApprovedTokenDepositor(address _depositor) external onlyOwner {
        approvedTokenDepositor[_depositor] = true;
    }

    function removeApprovedTokenDepositor(address _depositor) external onlyOwner {
        approvedTokenDepositor[_depositor] = false;
    }

    modifier onlyApprovedTokenDepositor() {
      require(approvedTokenDepositor[_msgSender()] == true, "SpoilerPoint: No authority");
      _;
    }

    function setwithdrawActive(bool _activate) external onlyOwner {
        withdrawActive = _activate;
    }

    function depositToken(address _token, uint256 _amount) external onlyApprovedTokenDepositor {
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        depositorTokenBalance[_msgSender()][_token] += _amount;

        emit Deposit(_token, _msgSender(), _amount);
    }

    function withdrawToken(address _token, address _to, uint256 _amount) external nonReentrant withdrawActivated onlyApprovedTokenDepositor {
        uint256 tokenBalance = depositorTokenBalance[_msgSender()][_token];
        require(tokenBalance >= _amount, "SpoilerTreasury: Not enough balance");
        
        unchecked {
                depositorTokenBalance[_msgSender()][_token] = tokenBalance - _amount;
            }
        IERC20(_token).safeTransfer(_to, _amount);

        emit Withdraw(_token, _msgSender(), _to, _amount);
    }

    function withdraw(address _token, address _to, uint256 _amount) external nonReentrant onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function withdrawNative(address payable _to, uint256 _amount) external nonReentrant onlyOwner {
        _to.transfer(_amount);
    }

    receive () external payable {}
}
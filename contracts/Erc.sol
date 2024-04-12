pragma solidity ^0.8.24;

import './libraries/SafeMath.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * tax 기능 추가
 * marketing wallet 추가 + marketing wallet 으로 자금 보내기
 */
contract VectorERC is IERC20, Context {
    using SafeMath for uint256;

    string public constant name = 'test';
    string public constant symbol = 'test';

    uint8 public immutable decimal;
    uint256 public immutable totalSupply;
    address public immutable owner;

    mapping(address => uint256) private userBalances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(uint8 _decimal, uint256 _totalSupply) {
        decimal = _decimal;
        totalSupply = _totalSupply * 10 ** _decimal;
        owner = msg.sender;

        userBalances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return userBalances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(recipient, amount);

        return true;
    }

    function _transfer(address recipient, uint256 amount) internal {
        userBalances[msg.sender] = userBalances[msg.sender].sub(amount);
        userBalances[recipient] = userBalances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');
        allowances[owner][spender] = amount;

        emit Approval(owner, _msgSender(), amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(recipient, amount);
        _approve(
            recipient,
            _msgSender(),
            allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    address public immutable owner;

    string public constant name = "ian";
    string public constant symbol = "I";
    uint8 public constant decimals = 2;

    uint public totalSupply;
    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowances;

    onstructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10**decimals;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        require(balances[msg.sender] >= amount,"balance is insufficient");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool){
        require(balances[msg.sender] >= amount,"balance is insufficient");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view returns (uint) {
        return allowances[_owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowances[from][msg.sender] >= amount, "allowance exceeded");
        require(balances[msg.sender] >= amount,"balance is insufficient");

        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function mint(uint amount) external onlyOwner returns (bool) {
        totalSupply += amount;
        balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    function burn(uint amount) external onlyOwner returns (bool) {
        require(balances[msg.sender] >= amount, "balance is insufficient");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"access denied");_;
    }
}

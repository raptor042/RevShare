// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RevShare {
    address public owner;

    address public token;

    uint256 public pool = 0;

    uint256 public minDeposit = 0.01 ether;

    uint256 public minBalance = 1 ether;

    mapping (address => uint256) public timestamps;

    constructor(address _token) {
        owner = msg.sender;

        token = _token;
    }

    event Pool_Funded(uint256 amount);

    event Claimed(address indexed user, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function fundPool() public payable onlyOwner {
        require(msg.value >= minDeposit, "Minimium prize pool requirement is 1 ETH.");

        pool += msg.value;

        emit Pool_Funded(msg.value);
    }

    function claim() public payable {
        require(pool > 0, "Prize pool is empty.");

        uint256 duration = timestamps[msg.sender] - block.timestamp;

        require(duration >= 86400, "Please wait for the next share unlock.");

        IERC20 Token = IERC20(token);

        require(Token.balanceOf(msg.sender) >= minBalance, "You do not HODL enough of the token.");

        uint256 ratio = Token.balanceOf(msg.sender) / Token.totalSupply();

        uint256 dividend = (ratio * pool) / 100;

        (bool os, ) = payable(msg.sender).call{value: dividend}("");
        require(os);

        pool -= dividend;

        timestamps[msg.sender] = block.timestamp;

        emit Claimed(msg.sender, dividend);
    }
}

 

pragma solidity ^0.4.23;

contract ERC20 {

     
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

     
    function balanceOf(address user) public view returns (uint256);
    function allowance(address user, address spender) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool); 
    function approve(address spender, uint256 value) public returns (bool); 

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed user, address indexed spender, uint256 value);
}

contract BatchTransfer {
    address private _owner;
    address private _erc20_address;
    mapping(address => bool) private _authed_addresses;

    constructor(address erc20_address) public {
        _owner = msg.sender;
        _erc20_address = erc20_address;
        _authed_addresses[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "require owner permission");
        _;
    }

    modifier onlyAuthed() {
        require(_authed_addresses[msg.sender], "require auth permission");
        _;
    }

     
    function updateAuth(address auth_address, bool is_auth) public onlyOwner {
        _authed_addresses[auth_address] = is_auth;
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    function erc20Address() public view returns (address) {
        return _erc20_address;
    }

     
    function isAuthed(address authed_address) public view returns (bool){
        return _authed_addresses[authed_address];
    }

     
    function transferFrom(address token_holder, address[] token_receivers, uint256[] values) public onlyAuthed returns (bool) {
        require(token_receivers.length == values.length, "token_receiver's size must eq value's size");
        require(token_receivers.length > 0, "token_receiver's length must gt 0");
        
        uint length = token_receivers.length;

         
        uint i = 0;
        uint value = 0;
        uint total_value = 0;

        for(i = 0; i < length; ++i) {
            value = values[i];
            require(value > 0, "value must gt 0");
            total_value += value;
        }
        
        ERC20 token_contract = ERC20(_erc20_address);
        uint256 holder_balance = token_contract.balanceOf(token_holder);
        require(holder_balance >= total_value, "balance of holder must gte total_value");
        uint256 my_allowance = token_contract.allowance(token_holder, this);
        require(my_allowance >= total_value, "allowance to contract must gte total_value");

         
        for(i = 0; i < length; ++i) {
            address token_receiver = token_receivers[i];
            value = values[i];
            bool is_success = token_contract.transferFrom(token_holder, token_receiver, value);
            require(is_success, "transaction should be success");
        }

        return true;
    }
}
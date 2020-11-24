 

pragma solidity ^0.4.24;

contract Tokens {
    address public owner;
    mapping(string => uint) supply;  
    mapping(string => mapping(address => uint)) balances;
    uint public fee;  

    constructor(uint _fee) public {
        owner = msg.sender;
        fee = _fee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function subtr(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function addit(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

     
    function mint(string _name, uint _supply) public payable {
        require(msg.value >= fee);  
        require(supply[_name] == 0);  
        supply[_name] = _supply;
        balances[_name][msg.sender] = _supply;
        emit Mint(_name, _supply);
    }

    function transfer(string _name, address _to, uint _amount) external {
        require(_amount <= balances[_name][msg.sender]);
        balances[_name][msg.sender] = subtr(balances[_name][msg.sender], _amount);
        balances[_name][_to] = addit(balances[_name][_to], _amount);
        emit Transfer(_name, msg.sender, _to, _amount);
    }

    function balanceOf(string _name, address _address) external view returns(uint) {
        return balances[_name][_address];
    }

    function supplyOf(string _name) external view returns(uint) {
        return supply[_name];
    }

    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

     
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    event Transfer(string indexed name, address indexed from, address indexed to, uint amount);
    event Mint(string indexed name, uint supply);
}
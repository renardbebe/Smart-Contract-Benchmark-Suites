 

pragma solidity ^0.4.25;

contract CompanyToken {

     
    string public name;  
    string public symbol;  
    uint8 public decimals;  
    uint256 public totalSupply;  
    address public owner;  
    uint256 public rate;  
	bool public allow_buy;  
    mapping(address => uint256) balances;  

         
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed owner, uint256 value);
    event SetOwner(address indexed owner);
    event SetAllowBuy(bool allow_buy);
    event SetRate(uint256 rate);
    event CreateToken(address indexed sender, uint256 value);
    
     
    constructor() public {
        totalSupply = 2500000;  
        name = "BSOnders";
        symbol = "BSO";
        decimals = 2;
        rate = 190;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        allow_buy = false;
    }
    
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length >= size + 4);
		_;
	}
	
     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) private returns (bool success) {
        require(balances[_from] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }    

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

      
    function setRate(uint256 _value) public onlyOwner returns(bool success) {
        rate = _value;
        emit SetRate(_value);
        return true;
    }        

    function setOwner(address _owner) public onlyOwner returns (bool success) {
        owner = _owner;
        emit SetOwner(_owner);
        return true;
    }    

    function setAllowBuy(bool _value) public onlyOwner returns(bool success) {
        allow_buy = _value;
        emit SetAllowBuy(_value);
        return true;
    }

     
    function distribute(address[] recipients, uint256[] _value) public onlyOwner returns (bool success) {
        for(uint i = 0; i < recipients.length; i++) {
            transferFrom(owner, recipients[i], _value[i]);
        }
        return true;
    }    
   
    function mint(uint256 _value) private returns (bool success) {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender] + _value;
        totalSupply = totalSupply + _value;
        emit Mint(msg.sender, _value);
        return true;
    }
    
     
  
     
    function createToken(uint256 _value) private returns (bool success) {
         
         
        uint256 tokens = rate * _value * 100 / (1 ether);
        mint(tokens);
        emit CreateToken(msg.sender, _value);
        return true;
    }

      
    function() external payable {
        if(allow_buy) {
            createToken(msg.value);
        } else {
            revert();  
        }
    }
}
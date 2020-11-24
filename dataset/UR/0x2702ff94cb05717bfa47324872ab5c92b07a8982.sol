 

pragma solidity ^0.4.0;


 
contract Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

     
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address owner) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is Token {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public maxSupply;

     
     
     
     
     
    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[msg.sender] < _value) {
             
            revert();
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
             
            revert();
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }
}


 
contract SolarNA is StandardToken {

     
    string constant public name = "SolarNA Token";
    string constant public symbol = "SOLA";
    uint8 constant public decimals = 3;
    address public owner;
    uint remaining;
    uint divPrice = 10 ** 12;

     
     
     
     
     
    function SolarNA(address[] presale_addresses, uint[] tokens)
        public
    {
        uint assignedTokens;
        owner = msg.sender;
        maxSupply = 500000 * 10**3;
        for (uint i=0; i<presale_addresses.length; i++) {
            if (presale_addresses[i] == 0) {
                 
                revert();
            }
            balances[presale_addresses[i]] += tokens[i];
            assignedTokens += tokens[i];
            emit Transfer(0, presale_addresses[i], tokens[i]);  
        }
         
        remaining = maxSupply - assignedTokens;
        assignedTokens += remaining;
        if (assignedTokens != maxSupply) {
            revert();
        }
    }

     
    function changePrice(bool _conditon) public returns (uint) {
        require(msg.sender == owner);
        if (_conditon) {
            divPrice *= 2;
        }
        return divPrice;
    }

    function () public payable {
         
        uint value = msg.value / uint(divPrice);
        require(remaining >= value && value != 0);
        balances[msg.sender] += value;
        remaining -= value;
        emit Transfer(address(0), msg.sender, value);
    }
    
     
    function transferAll() public returns (bool) {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        return true;
    }

     
    function totalSupply()  public constant returns (uint256 supply) {
        return maxSupply;
    }
    
     
    function remainingTokens() public view returns (uint256) {
        return remaining;
    } 

}
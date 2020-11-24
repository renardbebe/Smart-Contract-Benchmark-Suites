 

pragma solidity ^0.4.11;

 
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;
    uint constant preIcoPrice = 4101;
    uint constant icoPrice = 2255;

    function mul(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }

    function sub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

     
    function presaleVolumeBonus(uint256 price) internal returns (uint256) {

         
        uint256 val = div(price, preIcoPrice);

        if(val >= 100 * BASE) return add(price, price * 1/20);  
        if(val >= 50 * BASE) return add(price, price * 3/100);  
        if(val >= 20 * BASE) return add(price, price * 1/50);   

        return price;
    }

	 
    function volumeBonus(uint256 etherValue) internal returns (uint256) {
		
        if(etherValue >= 1000000000000000000000) return 15; 
        if(etherValue >=  500000000000000000000) return 10;  
        if(etherValue >=  300000000000000000000) return 7;   
        if(etherValue >=  100000000000000000000) return 5;   
        if(etherValue >=   50000000000000000000) return 3;    
        if(etherValue >=   20000000000000000000) return 2;    

        return 0;
    }

	 
    function dateBonus(uint startIco) internal returns (uint256) {

         
        uint daysFromStart = (now - startIco) / DAY_IN_SECONDS + 1;

        if(daysFromStart == 1) return 15;  
        if(daysFromStart == 2) return 10;  
        if(daysFromStart == 3) return 10;  
        if(daysFromStart == 4) return 5;   
        if(daysFromStart == 5) return 5;   
        if(daysFromStart == 6) return 5;   

		 
        return 0;
    }

}


 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
     
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    address[] public owners;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract CarTaxiToken is StandardToken, SafeMath {
     
    string public constant name = "CarTaxi";
    string public constant symbol = "CTX";
    uint public constant decimals = 18;

     

    address public icoContract = 0x0;
     

    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }

     

     
     
    function CarTaxiToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }

     
     
     
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
    }

     
     
     
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = add(balances[_to], _value);

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}
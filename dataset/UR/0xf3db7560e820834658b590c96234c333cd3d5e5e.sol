 

 
 
pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract CoinPokerToken {
    using SafeMath for uint;
     
    string constant public standard = "ERC20";
    string constant public name = "Poker Chips";
    string constant public symbol = "CHP";
    uint8 constant public decimals = 18;
    uint _totalSupply = 500000000e18;  
    uint constant public tokensPreICO = 100000000e18;  
    uint constant public tokensICO = 275000000e18;  
    uint constant public teamReserve = 50000000e18;  
    uint constant public tournamentsReserve = 75000000e18;  
    uint public startTime = 1516960800;  
    address public ownerAddr;
    address public preIcoAddr;  
    address public tournamentsAddr;  
    address public cashierAddr;  
    bool burned;

     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed spender, uint value);
    event Burned(uint amount);

     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function totalSupply() constant returns (uint) {
        return _totalSupply;
    }

     
    function CoinPokerToken(address _ownerAddr, address _preIcoAddr, address _tournamentsAddr, address _cashierAddr) {
        ownerAddr = _ownerAddr;
        preIcoAddr = _preIcoAddr;
        tournamentsAddr = _tournamentsAddr;
        cashierAddr = _cashierAddr;
        balances[ownerAddr] = _totalSupply;  
    }

     
    function transfer(address _to, uint _value) returns(bool) {
        if (now < startTime)   
            require(_to == cashierAddr);  
        balances[msg.sender] = balances[msg.sender].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        Transfer(msg.sender, _to, _value);  
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint _value) returns(bool) {
        if (now < startTime)   
            require(_from == ownerAddr || _to == cashierAddr);
        var _allowed = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowed[_from][msg.sender] = _allowed.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
	
     
     
    function approve(address _spender, uint _value) returns (bool) {
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function percent(uint numerator, uint denominator, uint precision) public constant returns(uint quotient) {
        uint _numerator = numerator.mul(10 ** (precision.add(1)));
        uint _quotient =  _numerator.div(denominator).add(5).div(10);
        return (_quotient);
    }

     
     
     
     
     
     
    function burn() {
         
        if (!burned && now > startTime) {
             
            uint total_sold = _totalSupply.sub(balances[ownerAddr]);
            total_sold = total_sold.add(tokensPreICO);
            uint total_ico_amount = tokensPreICO.add(tokensICO);
            uint percentage = percent(total_sold, total_ico_amount, 8);
            uint tournamentsAmount = tournamentsReserve.mul(percentage).div(100000000);

             
            uint totalReserve = teamReserve.add(tokensPreICO);
            totalReserve = totalReserve.add(tournamentsAmount);
            uint difference = balances[ownerAddr].sub(totalReserve);

             
            balances[preIcoAddr] = balances[preIcoAddr].add(tokensPreICO);
            balances[tournamentsAddr] = balances[tournamentsAddr].add(tournamentsAmount);
            balances[ownerAddr] = teamReserve;

             
            _totalSupply = _totalSupply.sub(difference);
            burned = true;
            Burned(difference);
        }
    }
}
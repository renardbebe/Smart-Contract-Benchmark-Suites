 

 
 
pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
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

contract LympoToken {
    using SafeMath for uint;
     
    string constant public standard = "ERC20";
    string constant public name = "Lympo tokens";
    string constant public symbol = "LYM";
    uint8 constant public decimals = 18;
    uint _totalSupply = 1000000000e18;  
    uint constant public tokensPreICO = 265000000e18;  
    uint constant public tokensICO = 385000000e18;  
    uint constant public teamReserve = 100000000e18;  
    uint constant public advisersReserve = 30000000e18;  
    uint constant public ecosystemReserve = 220000000e18;  
    uint constant public ecoLock23 = 146652000e18;  
    uint constant public ecoLock13 = 73326000e18;  
    uint constant public startTime = 1519815600;  
    uint public lockReleaseDate1year;
    uint public lockReleaseDate2year;
    address public ownerAddr;
    address public ecosystemAddr;
    address public advisersAddr;
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

     
    function totalSupply() constant returns (uint totalSupply) {
        totalSupply = _totalSupply;
    }

     
    function LympoToken(address _ownerAddr, address _advisersAddr, address _ecosystemAddr) {
        ownerAddr = _ownerAddr;
        advisersAddr = _advisersAddr;
        ecosystemAddr = _ecosystemAddr;
        lockReleaseDate1year = startTime + 1 years;  
        lockReleaseDate2year = startTime + 2 years;  
        balances[ownerAddr] = _totalSupply;  
    }
	
     
    function transfer(address _to, uint _value) returns(bool) {
        require(now >= startTime);  

         
        if (msg.sender == ownerAddr && now < lockReleaseDate2year)
            require(balances[msg.sender].sub(_value) >= teamReserve);

         
        if (msg.sender == ecosystemAddr && now < lockReleaseDate1year)
            require(balances[msg.sender].sub(_value) >= ecoLock23);
        else if (msg.sender == ecosystemAddr && now < lockReleaseDate2year)
            require(balances[msg.sender].sub(_value) >= ecoLock13);

        balances[msg.sender] = balances[msg.sender].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        Transfer(msg.sender, _to, _value);  
        return true;
    }
	
     
     
    function transferFrom(address _from, address _to, uint _value) returns(bool) {
        if (now < startTime)   
            require(_from == ownerAddr);

         
        if (_from == ownerAddr && now < lockReleaseDate2year)
            require(balances[_from].sub(_value) >= teamReserve);

         
        if (_from == ecosystemAddr && now < lockReleaseDate1year)
            require(balances[_from].sub(_value) >= ecoLock23);
        else if (_from == ecosystemAddr && now < lockReleaseDate2year)
            require(balances[_from].sub(_value) >= ecoLock13);

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

     
     
     
    function burn() {
         
        if (!burned && now > startTime) {
            uint totalReserve = ecosystemReserve.add(teamReserve);
            totalReserve = totalReserve.add(advisersReserve);
            uint difference = balances[ownerAddr].sub(totalReserve);
            balances[ownerAddr] = teamReserve;
            balances[advisersAddr] = advisersReserve;
            balances[ecosystemAddr] = ecosystemReserve;
            _totalSupply = _totalSupply.sub(difference);
            burned = true;
            Burned(difference);
        }
    }
}
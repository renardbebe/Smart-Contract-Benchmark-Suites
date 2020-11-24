 

pragma solidity ^0.4.11;

contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        Assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        Assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        Assert(c >= a && c >= b);
        return c;
    }

    function Assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}

contract Kubera is SafeMath {
     
    string public standard = 'ERC20';
    string public name = 'Kubera token';
    string public symbol = 'KBR';
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
    uint public tokensSoldToInvestors = 0;
    uint public maxGoalInICO = 2100000000;
     
    uint256 public startTime = 1510325999;
     
    bool burned;
    bool hasICOStarted;
     
    address tokensHolder = 0x94B4776F8331DF237E087Ed548A3c8b4932D131B;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferToReferral(address indexed referralAddress, uint256 value);
    event Approval(address indexed Owner, address indexed spender, uint256 value);
    event Burned(uint amount);

     
    function Kubera() {
        owner = 0x084bf76c9ba9106d6114305fae9810fbbdb157d9;
         
        balanceOf[owner] = 2205000000;
         
        totalSupply      = 2205000000;
    }

     
    function transfer(address _to, uint256 _value) returns(bool success) {
         
        if (now < startTime) {
            revert();
        }

         
        if (msg.sender == owner && !burned) {
            burn();
            return;
        }

         
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
         
        Transfer(msg.sender, _to, _value);

        return true;
    }


     
    function approve(address _spender, uint256 _value) returns(bool success) {
        if( now < startTime && hasICOStarted) {  
            revert();
        }
        hasICOStarted = true;
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (now < startTime && _from != owner) revert();  
         
        if (_from == owner && now >= startTime && !burned) {
            burn();
            return;
        }
        if (now < startTime){
            if(_value < maxGoalInICO ) {
                tokensSoldToInvestors = safeAdd(tokensSoldToInvestors, _value);
            } else {
                _value = safeSub(_value, maxGoalInICO);
            }
        }
        var _allowance = allowance[_from][msg.sender];
         
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);

        return true;
    }

    function burn(){
         
        if(!burned && ( now > startTime || tokensSoldToInvestors >= maxGoalInICO) ) {
             
            totalSupply = safeSub(totalSupply, balanceOf[owner]) + 900000000;
            uint tokensLeft = balanceOf[owner];
            balanceOf[owner] = 0;
            balanceOf[tokensHolder] = 900000000;
            startTime = now;
            burned = true;
            Burned(tokensLeft);
        }
    }

}
 

pragma solidity ^0.4.18;

 
contract ERC223 {
    function totalSupply() constant public returns (uint256 outTotalSupply);
    function balanceOf( address _owner) constant public returns (uint256 balance);
    function transfer( address _to, uint256 _value) public returns (bool success);
    function transfer( address _to, uint256 _value, bytes _data) public returns (bool success);
    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success);
    function approve( address _spender, uint256 _value) public returns (bool success);
    function allowance( address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer( address indexed _from, address indexed _to, uint _value, bytes _data);
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);
}


contract ERC223Receiver { 
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

 
}



 
contract StandardToken is ERC223, SafeMath {
        
    uint256 public supplyNum;
    
    uint256 public decimals;

     
    mapping(address => uint) mapBalances;

     
    mapping (address => mapping (address => uint)) mapApproved;

     
    function isToken() public pure returns (bool weAre) {
        return true;
    }


    function totalSupply() constant public returns (uint256 outTotalSupply) {
        return supplyNum;
    }

    
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        mapBalances[msg.sender] = safeSub(mapBalances[msg.sender], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        if (codeLength > 0) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    
    function transfer(address _to, uint _value) public returns (bool) {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        mapBalances[msg.sender] = safeSub(mapBalances[msg.sender], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        if (codeLength > 0) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
        return true;
    }
    
    

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        mapApproved[_from][msg.sender] = safeSub(mapApproved[_from][msg.sender], _value);
        mapBalances[_from] = safeSub(mapBalances[_from], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        bytes memory empty;
        emit Transfer(_from, _to, _value, empty);
                
        return true;
    }

    function balanceOf(address _owner) view public returns (uint balance)    {
        return mapBalances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success)    {

         
         
         
         
        require (_value != 0); 
        require (mapApproved[msg.sender][_spender] == 0);

        mapApproved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint remaining)    {
        return mapApproved[_owner][_spender];
    }

}




 
contract BetOnMe is StandardToken {

    string public name = "BetOnMe";
    string public symbol = "BOM";
    
    
    address public coinMaster;
    
    
     
    event UpdatedInformation(string newName, string newSymbol);

    function BetOnMe() public {
        supplyNum = 1000000000000 * (10 ** 18);
        decimals = 18;
        coinMaster = msg.sender;

         
        mapBalances[coinMaster] = supplyNum;
    }

     
    function setTokenInformation(string _name, string _symbol) public {
        require(msg.sender == coinMaster) ;

        require(bytes(name).length > 0 && bytes(symbol).length > 0);

        name = _name;
        symbol = _symbol;
        emit UpdatedInformation(name, symbol);
    }
    
    
    
     
    function withdrawTokens() external {
        uint256 fundNow = balanceOf(this);
        transfer(coinMaster, fundNow); 
        
        uint256 balance = address(this).balance;
        coinMaster.transfer(balance); 
    }

}
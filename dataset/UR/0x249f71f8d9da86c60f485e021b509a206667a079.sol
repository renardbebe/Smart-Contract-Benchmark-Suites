 

pragma solidity ^0.4.15;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
} 

contract AbstractSingularDTVFund {
    function softWithdrawRewardFor(address forAddress) returns (uint);
}

 
 
 
contract SingularDTVToken is StandardToken {
    string public version = "0.1.0";

     
    AbstractSingularDTVFund public singularDTVFund;

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

     
     
     
    function transfer(address to, uint256 value)
        returns (bool)
    {
         
        singularDTVFund.softWithdrawRewardFor(msg.sender);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transfer(to, value);
    }

     
     
     
     
    function transferFrom(address from, address to, uint256 value)
        returns (bool)
    {
         
        singularDTVFund.softWithdrawRewardFor(from);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transferFrom(from, to, value);
    }

    function SingularDTVToken(address sDTVFundAddr, address _wallet, string _name, string _symbol, uint _totalSupply) {
        if(sDTVFundAddr == 0 || _wallet == 0) {
             
            revert();
        }

        balances[_wallet] = _totalSupply;
        totalSupply = _totalSupply;

        name = _name;
        symbol = _symbol;

        singularDTVFund = AbstractSingularDTVFund(sDTVFundAddr);

        Transfer(this, _wallet, _totalSupply);
    }
}
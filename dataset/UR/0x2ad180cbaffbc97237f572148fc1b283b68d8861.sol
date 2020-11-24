 

pragma solidity ^0.4.11;


contract ERC20 {

  function balanceOf(address who) constant public returns (uint);
  function allowance(address owner, address spender) constant public returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}

 
 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable public returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}



 
 
 

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}


contract ControlledToken is ERC20, Controlled {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = '1.0';        
    uint256 public totalSupply;

    function ControlledToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        )  {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }


    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);

        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(msg.sender, _to, _value));
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
         

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _value));
        }

        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _value));
        }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        totalSupply = curTotalSupply + _amount;
        balances[_owner]  = previousBalanceTo + _amount;
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        totalSupply = curTotalSupply - _amount;
        balances[_owner] = previousBalanceFrom - _amount;
        Transfer(_owner, 0, _amount);
        return true;
    }

     
     
     
    function ()  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ControlledToken token = ControlledToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


}



contract IZXToken is ControlledToken {

   function IZXToken() ControlledToken( 1, 'IZX Token', 18, 'IZX' ) public {}

}
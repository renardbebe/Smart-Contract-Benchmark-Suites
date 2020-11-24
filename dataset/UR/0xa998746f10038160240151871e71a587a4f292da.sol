 

pragma solidity ^0.4.25;
interface TransferRecipient {
	function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns(bool);
}

interface ApprovalRecipient {
	function approvalFallback(address _from, uint256 _value, bytes _extraData) public returns(bool);
}
contract ERCToken {
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	uint256 public  totalSupply;
	mapping (address => uint256) public balanceOf;

	function allowance(address _owner,address _spender) public view returns(uint256);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public  returns (bool success);


}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract MyToken is ERCToken {

    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals=18;

    mapping (address => mapping (address => uint256)) internal allowed;

   
  function MyToken (
        string tokenName,
        string tokenSymbol,
        uint256 initSupply
    ) public {
        totalSupply = initSupply * 10 ** 18;   
        balanceOf[msg.sender] = totalSupply;                    
        name = tokenName;                                       
        symbol = tokenSymbol;
     }

    function greet() view public returns (string) {
        return 'hello';
    }

    
    function _transfer(address _from, address _to, uint _value) internal {

         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousbalanceOf = balanceOf[_from].add(balanceOf[_to]);

         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] =balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousbalanceOf);
    }


     
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferAndCall(address _to, uint256 _value, bytes _data)
        public
        returns (bool success) {
        _transfer(msg.sender,_to, _value);
        if(_isContract(_to))
        {
            TransferRecipient spender = TransferRecipient(_to);
            if(!spender.tokenFallback(msg.sender, _value, _data))
            {
                revert();
            }
        }
        return true;
    }

    function _isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender]= allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner,address _spender) public view returns(uint256){
        return allowed[_owner][_spender];

    }

   
    function approve(address _spender, uint256 _value) public  returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {

        allowed[msg.sender][_spender] = _value;
        if(_isContract(_spender)){
            ApprovalRecipient spender = ApprovalRecipient(_spender);
            if(!spender.approvalFallback(msg.sender, _value, _extraData)){
                revert();
            }
        }
        Approval(msg.sender, _spender, _value);
        return true;

    }

}
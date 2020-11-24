 

pragma solidity ^0.4.18;

 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Tancoin is ERC20Interface {
    uint256 public constant decimals = 8;

    string public constant symbol = "Tancoin";
    string public constant name = "Tancoin";

    uint256 public _totalSupply = 10 ** 16;  

     
    address public owner;

     
    mapping(address => uint256) private balances;

     
    mapping(address => mapping (address => uint256)) private allowed;

     
    mapping(address => bool) private approvedInvestorList;

     
    mapping(address => uint256) private deposit;


     
    uint256 public totalTokenSold = 0;


     
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }


     
    function Tancoin()
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

     
     
    function totalSupply()
        public
        constant
        returns (uint256) {
        return _totalSupply;
    }


     
     
     
    function balanceOf(address _addr)
        public
        constant
        returns (uint256) {
        return balances[_addr];
    }

     
     
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }

     
     
     
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
	}


     
     
     
     
    function transfer(address _to, uint256 _amount)
        public

        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) &&
             (balances[_to] + _amount > balances[_to]) ) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public

    returns (bool success) {
        if (balances[_from] >= _amount && _amount > 0 && allowed[_from][msg.sender] >= _amount) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount)
        public

        returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () public payable{
        revert();
    }

}
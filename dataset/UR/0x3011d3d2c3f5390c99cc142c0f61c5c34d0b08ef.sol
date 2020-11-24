 

 

pragma solidity ^0.5.0;

 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ST is ERC20Interface {
    uint256 public constant decimals = 18;

    string public constant symbol = "ST";
    string public constant name = "Super Token";

    uint256 public _totalSupply = 2100000000*(10 ** 18);

     
    address public owner;

     
    mapping(address => uint256) private balances;

     
    mapping(address => mapping (address => uint256)) private allowed;

     
    mapping(address => bool) private approvedInvestorList;

     
     

     
     


     
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }



     
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

     
     
    function totalSupply()
        public view returns (uint256) {
        return _totalSupply;
    }





     
     
     
    function balanceOf(address _addr)
        public view returns (uint256) {
        return balances[_addr];
    }

     
     
    function isApprovedInvestor(address _addr)
        public view returns (bool) {
        return approvedInvestorList[_addr];
    }

     
     
     
     
     
     
     


     
     
     
     
    function transfer(address _to, uint256 _amount)
        public returns (bool success) {
            
         
         
         
        require(_to != address(0));
        require((balances[msg.sender] >= _amount) && (_amount >= 0) && (balances[_to] + _amount > balances[_to]));
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        success = true;
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public returns (bool success) {
        require(balances[_from] >= _amount && _amount > 0);
        require(allowed[_from][msg.sender] >= _amount);
        require(balances[_to] + _amount > balances[_to]);
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        success =  true;
    }

     
     
    function approve(address _spender, uint256 _amount)
        public

        returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () external payable {
        revert();
    }
}
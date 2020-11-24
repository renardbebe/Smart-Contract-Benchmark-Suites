 

pragma solidity ^0.4.24;

 
contract ERC20Interface {

     
     

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

     
     


    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.24;

 
contract PluginInterface
{
     
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

     
     
     
     
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

     
     
     
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}


contract CuteCoinInterface is ERC20Interface
{
    function mint(address target, uint256 mintedAmount) public;
    function mintBulk(address[] target, uint256[] mintedAmount) external;
    function burn(uint256 amount) external;
}

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.24;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

pragma solidity ^0.4.24;

 
 
 
 

interface TokenRecipientInterface
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

pragma solidity ^0.4.24;

 
interface TokenFallback
{
    function tokenFallback(address _from, uint _value, bytes _data) external;
}


contract CuteCoin is CuteCoinInterface, Ownable
{
    using SafeMath for uint;

    constructor() public
    {
        symbol = "CUTE";
        name = "Cute Coin";
        decimals = 18;
    }

    uint _totalSupply;
    mapping (address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

     
    mapping (address => bool) operatorAddress;

    function addOperator(address _operator) public onlyOwner
    {
        operatorAddress[_operator] = true;
    }

    function removeOperator(address _operator) public onlyOwner
    {
        delete(operatorAddress[_operator]);
    }

    modifier onlyOperator() {
        require(operatorAddress[msg.sender] || msg.sender == owner);
        _;
    }

    function withdrawEthFromBalance() external onlyOwner
    {
        owner.transfer(address(this).balance);
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
    function () payable public
    {
        revert();
    }

     

    function mint(address target, uint256 mintedAmount) public onlyOperator
    {
        balances[target] = balances[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(0, target, mintedAmount);
    }

    function mintBulk(address[] target, uint256[] mintedAmount) external onlyOperator
    {
        require(target.length == mintedAmount.length);
        for (uint i = 0; i < target.length; i++)
        {
            mint(target[i], mintedAmount[i]);
        }
    }

    function burn(uint256 amount) external
    {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, 0, amount);
    }


     

    function totalSupply() public constant returns (uint)
    {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance)
    {
        return balances[tokenOwner];
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        TokenRecipientInterface(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transferBulk(address[] to, uint[] tokens) public
    {
        require(to.length == tokens.length);
        for (uint i = 0; i < to.length; i++)
        {
            transfer(to[i], tokens[i]);
        }
    }

    function approveBulk(address[] spender, uint[] tokens) public
    {
        require(spender.length == tokens.length);
        for (uint i = 0; i < spender.length; i++)
        {
            approve(spender[i], tokens[i]);
        }
    }

 

     
    function transfer(address _to, uint _value, bytes _data) external returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transferToContract(address _to, uint _value, bytes _data) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        TokenFallback receiver = TokenFallback(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }


     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
         
            length := extcodesize(_addr)
        }
        return (length>0);
    }

     
    function transferToAddress(address _to, uint tokens, bytes _data) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        emit Transfer(msg.sender, _to, tokens, _data);
        return true;
    }

     
     
    function withdrawTokenFromBalance(ERC20Interface _tokenContract, address _withdrawToAddress)
        external
        onlyOperator
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }
}
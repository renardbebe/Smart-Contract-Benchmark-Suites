 

pragma solidity ^0.4.21;
 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
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

 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
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

 
 
 
 
contract SEPCToken is ERC20Interface, Ownable{
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

     
    uint public angelMaxAmount;
    uint public firstMaxAmount;
    uint public secondMaxAmount;
    uint public thirdMaxAmount;

     
    uint public angelCurrentAmount = 0;
    uint public firstCurrentAmount = 0;
    uint public secondCurrentAmount = 0;
    uint public thirdCurrentAmount = 0;

     
    uint public angelRate = 40000;
    uint public firstRate = 13333;
    uint public secondRate = 10000;
    uint public thirdRate = 6153;

     
    uint public teamHoldAmount = 700000000;

     
    uint public angelStartTime = 1528905600;   
    uint public firstStartTime = 1530201600;   
    uint public secondStartTime = 1531929600;  
    uint public thirdStartTime = 1534521600;   
    uint public endTime = 1550419200;  

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
     
     
    function SEPCToken() public {
        symbol = "SEPC";
        name = "SEPC";
        decimals = 18;
        angelMaxAmount = 54000000 * 10**uint(decimals);
        firstMaxAmount = 56000000 * 10**uint(decimals);
        secondMaxAmount= 90000000 * 10**uint(decimals);
        thirdMaxAmount = 100000000 * 10**uint(decimals);
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[msg.sender] = teamHoldAmount * 10**uint(decimals);
        emit Transfer(address(0), msg.sender, teamHoldAmount * 10**uint(decimals));
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
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

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function multiTransfer(address[] _addresses, uint256[] amounts) public returns (bool success){
        for (uint256 i = 0; i < _addresses.length; i++) {
            transfer(_addresses[i], amounts[i]);
        }
        return true;
    }

     
     
     
    function multiTransferDecimals(address[] _addresses, uint256[] amounts) public returns (bool success){
        for (uint256 i = 0; i < _addresses.length; i++) {
            transfer(_addresses[i], amounts[i] * 10**uint(decimals));
        }
        return true;
    }

     
     
     
    function () payable public {
          require(now < endTime && now >= angelStartTime);
          require(angelCurrentAmount <= angelMaxAmount && firstCurrentAmount <= firstMaxAmount && secondCurrentAmount <= secondMaxAmount && thirdCurrentAmount <= thirdMaxAmount);
          uint weiAmount = msg.value;
          uint rewardAmount;
          if(now >= angelStartTime && now < firstStartTime){
            rewardAmount = weiAmount.mul(angelRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            angelCurrentAmount = angelCurrentAmount.add(rewardAmount);
            require(angelCurrentAmount <= angelMaxAmount);
          }else if (now >= firstStartTime && now < secondStartTime){
            rewardAmount = weiAmount.mul(firstRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            firstCurrentAmount = firstCurrentAmount.add(rewardAmount);
            require(firstCurrentAmount <= firstMaxAmount);
          }else if(now >= secondStartTime && now < thirdStartTime){
            rewardAmount = weiAmount.mul(secondRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            secondCurrentAmount = secondCurrentAmount.add(rewardAmount);
            require(secondCurrentAmount <= secondMaxAmount);
          }else if(now >= thirdStartTime && now < endTime){
            rewardAmount = weiAmount.mul(thirdRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            thirdCurrentAmount = thirdCurrentAmount.add(rewardAmount);
            require(thirdCurrentAmount <= thirdMaxAmount);
          }
          owner.transfer(msg.value);
    }

     
     
     
    function collectToken()  public onlyOwner {
        require( now > endTime);
        balances[owner] = balances[owner].add(angelMaxAmount + firstMaxAmount + secondMaxAmount + thirdMaxAmount -angelCurrentAmount - firstCurrentAmount - secondCurrentAmount - thirdCurrentAmount);
    }
}
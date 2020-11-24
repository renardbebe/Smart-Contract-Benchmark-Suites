 

pragma solidity ^0.4.19;




 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract ThinkCoin is MintableToken {
  string public name = "ThinkCoin";
  string public symbol = "TCO";
  uint8 public decimals = 18;
  uint256 public cap;

  function ThinkCoin(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(mintingFinished == true);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(mintingFinished == true);
    return super.transferFrom(_from, _to, _value);
  }

  function() public payable {
    revert();
  }
}






contract LockingContract is Ownable {
  using SafeMath for uint256;

  event NotedTokens(address indexed _beneficiary, uint256 _tokenAmount);
  event ReleasedTokens(address indexed _beneficiary);
  event ReducedLockingTime(uint256 _newUnlockTime);

  ERC20 public tokenContract;
  mapping(address => uint256) public tokens;
  uint256 public totalTokens;
  uint256 public unlockTime;

  function isLocked() public view returns(bool) {
    return now < unlockTime;
  }

  modifier onlyWhenUnlocked() {
    require(!isLocked());
    _;
  }

  modifier onlyWhenLocked() {
    require(isLocked());
    _;
  }

  function LockingContract(ERC20 _tokenContract, uint256 _lockingDuration) public {
    require(_lockingDuration > 0);
    unlockTime = now.add(_lockingDuration);
    tokenContract = _tokenContract;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return tokens[_owner];
  }

   
   
   
  function noteTokens(address _beneficiary, uint256 _tokenAmount) external onlyOwner onlyWhenLocked {
    uint256 tokenBalance = tokenContract.balanceOf(this);
    require(tokenBalance == totalTokens.add(_tokenAmount));

    tokens[_beneficiary] = tokens[_beneficiary].add(_tokenAmount);
    totalTokens = totalTokens.add(_tokenAmount);
    NotedTokens(_beneficiary, _tokenAmount);
  }

  function releaseTokens(address _beneficiary) public onlyWhenUnlocked {
    uint256 amount = tokens[_beneficiary];
    tokens[_beneficiary] = 0;
    require(tokenContract.transfer(_beneficiary, amount)); 
    totalTokens = totalTokens.sub(amount);
    ReleasedTokens(_beneficiary);
  }

  function reduceLockingTime(uint256 _newUnlockTime) public onlyOwner onlyWhenLocked {
    require(_newUnlockTime >= now);
    require(_newUnlockTime < unlockTime);
    unlockTime = _newUnlockTime;
    ReducedLockingTime(_newUnlockTime);
  }
}





contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;

  event MintProposed(address indexed _beneficiary, uint256 _tokenAmount);
  event MintLockedProposed(address indexed _beneficiary, uint256 _tokenAmount);
  event MintApproved(address indexed _beneficiary, uint256 _tokenAmount);
  event MintLockedApproved(address indexed _beneficiary, uint256 _tokenAmount);
  event MintedAllocation(address indexed _beneficiary, uint256 _tokenAmount);
  event ProposerChanged(address _newProposer);
  event ApproverChanged(address _newApprover);

  ThinkCoin public token;
  LockingContract public lockingContract;
  address public proposer;  
  address public approver;  
  mapping(address => uint256) public mintProposals;
  mapping(address => uint256) public mintLockedProposals;
  uint256 public proposedTotal = 0;
  uint256 public saleCap;
  uint256 public saleStartTime;
  uint256 public saleEndTime;

  function Crowdsale(ThinkCoin _token,
                     uint256 _lockingPeriod,
                     address _proposer,
                     address _approver,
                     uint256 _saleCap,
                     uint256 _saleStartTime,
                     uint256 _saleEndTime
                     ) public {
    require(_saleCap > 0);
    require(_saleStartTime < _saleEndTime);
    require(_saleEndTime > now);
    require(_lockingPeriod > 0);
    require(_proposer != _approver);
    require(_saleStartTime >= now);
    require(_saleCap <= _token.cap());
    require(address(_token) != 0x0);

    token = _token;
    lockingContract = new LockingContract(token, _lockingPeriod);    
    proposer = _proposer;
    approver = _approver;
    saleCap = _saleCap;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
  }

  modifier saleStarted() {
    require(now >= saleStartTime);
    _;
  }

  modifier saleNotEnded() {
    require(now < saleEndTime);
    _;
  }

  modifier saleEnded() {
    require(now >= saleEndTime);
    _;
  }

  modifier onlyProposer() {
    require(msg.sender == proposer);
    _;
  }

  modifier onlyApprover() {
    require(msg.sender == approver);
    _;
  }

  function exceedsSaleCap(uint256 _additionalAmount) internal view returns(bool) {
    uint256 totalSupply = token.totalSupply();
    return totalSupply.add(_additionalAmount) > saleCap;
  }

  modifier notExceedingSaleCap(uint256 _amount) {
    require(!exceedsSaleCap(_amount));
    _;
  }

  function proposeMint(address _beneficiary, uint256 _tokenAmount) public onlyProposer saleStarted saleNotEnded
                                                                          notExceedingSaleCap(proposedTotal.add(_tokenAmount)) {
    require(_tokenAmount > 0);
    require(mintProposals[_beneficiary] == 0);
    proposedTotal = proposedTotal.add(_tokenAmount);
    mintProposals[_beneficiary] = _tokenAmount;
    MintProposed(_beneficiary, _tokenAmount);
  }

  function proposeMintLocked(address _beneficiary, uint256 _tokenAmount) public onlyProposer saleStarted saleNotEnded
                                                                         notExceedingSaleCap(proposedTotal.add(_tokenAmount)) {
    require(_tokenAmount > 0);
    require(mintLockedProposals[_beneficiary] == 0);
    proposedTotal = proposedTotal.add(_tokenAmount);
    mintLockedProposals[_beneficiary] = _tokenAmount;
    MintLockedProposed(_beneficiary, _tokenAmount);
  }

  function clearProposal(address _beneficiary) public onlyApprover {
    proposedTotal = proposedTotal.sub(mintProposals[_beneficiary]);
    mintProposals[_beneficiary] = 0;
  }

  function clearProposalLocked(address _beneficiary) public onlyApprover {
    proposedTotal = proposedTotal.sub(mintLockedProposals[_beneficiary]);
    mintLockedProposals[_beneficiary] = 0;
  }

  function approveMint(address _beneficiary, uint256 _tokenAmount) public onlyApprover saleStarted
                                                                   notExceedingSaleCap(_tokenAmount) {
    require(_tokenAmount > 0);
    require(mintProposals[_beneficiary] == _tokenAmount);
    mintProposals[_beneficiary] = 0;
    token.mint(_beneficiary, _tokenAmount);
    MintApproved(_beneficiary, _tokenAmount);
  }

  function approveMintLocked(address _beneficiary, uint256 _tokenAmount) public onlyApprover saleStarted
                                                                         notExceedingSaleCap(_tokenAmount) {
    require(_tokenAmount > 0);
    require(mintLockedProposals[_beneficiary] == _tokenAmount);
    mintLockedProposals[_beneficiary] = 0;
    token.mint(lockingContract, _tokenAmount);
    lockingContract.noteTokens(_beneficiary, _tokenAmount);
    MintLockedApproved(_beneficiary, _tokenAmount);
  }

  function mintAllocation(address _beneficiary, uint256 _tokenAmount) public onlyOwner saleEnded {
    require(_tokenAmount > 0);
    token.mint(_beneficiary, _tokenAmount);
    MintedAllocation(_beneficiary, _tokenAmount);
  }

  function finishMinting() public onlyOwner saleEnded {
    require(proposedTotal == 0);
    token.finishMinting();
    transferTokenOwnership();
  }

  function transferTokenOwnership() public onlyOwner saleEnded {
    token.transferOwnership(msg.sender);
  }

  function changeProposer(address _newProposer) public onlyOwner {
    require(_newProposer != approver);
    proposer = _newProposer;
    ProposerChanged(_newProposer);
  }

  function changeApprover(address _newApprover) public onlyOwner {
    require(_newApprover != proposer);
    approver = _newApprover;
    ApproverChanged(_newApprover);
  }
}
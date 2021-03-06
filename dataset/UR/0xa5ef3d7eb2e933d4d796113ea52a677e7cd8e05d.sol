 

pragma solidity ^0.4.24;

 
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 
contract PausableToken is StandardToken, Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;
    mapping(address => bool) public whitelist;

     
    function pause() onlyOwner public {
        require(!paused);
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner public {
        require(paused);
        paused = false;
        emit Unpause();
    }
     
    function setWhitelisted(address who, bool allowTransfers) onlyOwner public {
        whitelist[who] = allowTransfers;
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        require(!paused || whitelist[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(!paused || whitelist[msg.sender] || whitelist[_from]);
        return super.transferFrom(_from, _to, _value);
    }

}

 
contract RevocableToken is MintableToken {

    event Revoke(address indexed from, uint256 value);

    modifier canRevoke() {
        require(!mintingFinished);
        _;
    }

     
    function revoke(address _from, uint256 _value) onlyOwner canRevoke public returns (bool) {
        require(_value <= balances[_from]);
         
         

        balances[_from] = balances[_from].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Revoke(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
}

contract RewardsToken is RevocableToken,   PausableToken, BurnableToken, NoOwner {
    string public symbol = 'RWRD';
    string public name = 'Rewards Cash';
    uint8 public constant decimals = 18;

    uint256 public hardCap = 10 ** (18 + 9);  

     
    function mint(address _to, uint256 _amount) public returns (bool){
        require(totalSupply_.add(_amount) <= hardCap);
        return super.mint(_to, _amount);
    }


}
contract RewardsMinter is Claimable, NoOwner {
    using SafeMath for uint256;

    struct MintProposal {
        address beneficiary;     
        uint256 amount;          
        mapping(address => bool) signers;    
        uint256 weight;          
        bool minted;             
    }

    RewardsToken public token;
    mapping(address => uint256) public signers;      
    uint256 public requiredWeight;                   

    MintProposal[] public mintProposals;

    event SignerWeightChange(address indexed signer, uint256 oldWeight, uint256 newWeight);
    event RequiredWeightChange(uint256 oldWeight, uint256 newWeight);
    event MintProposalCreated(uint256 proposalId, address indexed beneficiary, uint256 amount);
    event MintProposalApproved(uint256 proposalId, address indexed signer);
    event MintProposalCompleted(uint256 proposalId, address indexed beneficiary, uint256 amount);

    modifier onlySigner(){
        require(signers[msg.sender] > 0 );
        _;
    }

    constructor(address _token, uint256 _requiredWeight, uint256 _ownerWeight) public {
        if(_token == 0x0){
            token = new RewardsToken();
            token.setWhitelisted(address(this), true);
            token.setWhitelisted(msg.sender, true);
            token.pause();
        }else{
            token = RewardsToken(_token);
        }

        requiredWeight = _requiredWeight;          
        signers[owner] = _ownerWeight;     
        emit SignerWeightChange(owner, 0, _ownerWeight);
    }

    function mintProposalCount() view public returns(uint256){
        return mintProposals.length;
    }

     
    function setSignerWeight(address signer, uint256 weight) onlyOwner external {
        emit SignerWeightChange(signer, signers[signer], weight);
        signers[signer] = weight;
    }
    function setRequiredWeight(uint256 weight) onlyOwner external {
        requiredWeight = weight;
    }

     
    function createProposal(address _beneficiary, uint256 _amount) onlySigner external returns(uint256){
        uint256 idx = mintProposals.length++;
        mintProposals[idx].beneficiary = _beneficiary;
        mintProposals[idx].amount = _amount;
        mintProposals[idx].minted = false;
        mintProposals[idx].signers[msg.sender] = true;
        mintProposals[idx].weight = signers[msg.sender];
        emit MintProposalCreated(idx, _beneficiary, _amount);
        emit MintProposalApproved(idx, msg.sender);
        mintIfWeightEnough(idx);
        return idx;
    }

     
    function approveProposal(uint256 idx, address _beneficiary, uint256 _amount) onlySigner external {
        require(mintProposals[idx].beneficiary == _beneficiary);
        require(mintProposals[idx].amount == _amount);
        require(mintProposals[idx].signers[msg.sender] == false);
        mintProposals[idx].signers[msg.sender] = true;
        mintProposals[idx].weight = mintProposals[idx].weight.add(signers[msg.sender]);
        emit MintProposalApproved(idx, msg.sender);
        mintIfWeightEnough(idx);
    }

     
    function mintIfWeightEnough(uint256 idx) internal {
        if(mintProposals[idx].weight >= requiredWeight && !mintProposals[idx].minted){
            mint(mintProposals[idx].beneficiary, mintProposals[idx].amount);
            mintProposals[idx].minted = true;
            emit MintProposalCompleted(idx, mintProposals[idx].beneficiary, mintProposals[idx].amount);
        }
    }

     
    function mint(address _to, uint256 _amount) internal returns (bool){
        return token.mint(_to, _amount);
    }


     
    function tokenPause() onlyOwner public {
        token.pause();
    }
    function tokenUnpause() onlyOwner public {
        token.unpause();
    }
    function tokenSetWhitelisted(address who, bool allowTransfers) onlyOwner public {
        token.setWhitelisted(who, allowTransfers);
    }
    function tokenRevoke(address _from, uint256 _value) onlyOwner public {
        token.revoke(_from, _value);
    }
    function tokenFinishMinting() onlyOwner public {
        token.finishMinting();
    }
}

contract RevokeHandler is Claimable, NoOwner {
    RewardsToken public token;
    constructor(address _token) public {
        token = RewardsToken(_token);
    }
    
    function getTokenAmount(address _holder) private view returns (uint256){
        return token.balanceOf(_holder);
    }
    
    function revokeTokens(address[] _holders) public onlyOwner {
       uint256 amount = 0;
       require(_holders.length > 0, "Empty holder addresses");
       for (uint i = 0; i < _holders.length; i++) {
         amount = getTokenAmount(_holders[i]);
         if(amount > 0) {
             token.revoke(_holders[i], amount);
         }
       }
   }
}
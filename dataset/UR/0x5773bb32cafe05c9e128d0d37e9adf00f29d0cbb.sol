 

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;



 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.18;



 
contract Restricted is Ownable {

     
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

     
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

     
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

 

pragma solidity ^0.4.24;


contract CanReclaimEther is Ownable {
    event ReclaimEther(address indexed to, uint256 amount);

     
    function reclaimEther() external onlyOwner {
        uint256 value = address(this).balance;
        owner.transfer(value);

        emit ReclaimEther(owner, value);
    }

     
    function reclaimEtherTo(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _to.transfer(_value);

        emit ReclaimEther(_to, _value);
    }
}

 

pragma solidity ^0.4.24;




contract CanReclaimTokens is Ownable {
    using SafeERC20 for ERC20Basic;

    event ReclaimTokens(address indexed to, uint256 amount);

     
    function reclaimToken(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        _token.safeTransfer(owner, balance);

        emit ReclaimTokens(owner, balance);
    }

     
    function reclaimTokenTo(ERC20Basic _token, address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _token.safeTransfer(_to, _value);

        emit ReclaimTokens(_to, _value);
    }
}

 

pragma solidity ^0.4.24;









 
contract MonethaClaimHandler is Restricted, Pausable, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC20 for ERC20Basic;

    event MinStakeUpdated(uint256 previousMinStake, uint256 newMinStake);

    event ClaimCreated(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimAccepted(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimResolved(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimClosedAfterAcceptanceExpired(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimClosedAfterResolutionExpired(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimClosedAfterConfirmationExpired(uint256 indexed dealId, uint256 indexed claimIdx);
    event ClaimClosed(uint256 indexed dealId, uint256 indexed claimIdx);

    ERC20 public token;       
    uint256 public minStake;  

     
    enum State {
        Null,
        AwaitingAcceptance,
        AwaitingResolution,
        AwaitingConfirmation,
        ClosedAfterAcceptanceExpired,
        ClosedAfterResolutionExpired,
        ClosedAfterConfirmationExpired,
        Closed
    }

    struct Claim {
        State state;
        uint256 modified;
        uint256 dealId;  
        bytes32 dealHash;  
        string reasonNote;  
        bytes32 requesterId;  
        address requesterAddress;  
        uint256 requesterStaked;  
        bytes32 respondentId;  
        address respondentAddress;  
        uint256 respondentStaked;  
        string resolutionNote;  
    }

    Claim[] public claims;

    constructor(ERC20 _token, uint256 _minStake) public {
        require(_token != address(0), "must be valid token address");

        token = _token;
        _setMinStake(_minStake);
    }

     
    function setMinStake(uint256 _newMinStake) external whenNotPaused onlyMonetha {
        _setMinStake(_newMinStake);
    }

     
    function getClaimsCount() public constant returns (uint256 count) {
        return claims.length;
    }

     
    function create(
        uint256 _dealId,
        bytes32 _dealHash,
        string _reasonNote,
        bytes32 _requesterId,
        bytes32 _respondentId,
        uint256 _amountToStake
    ) external whenNotPaused {
        require(bytes(_reasonNote).length > 0, "reason note must not be empty");
        require(_dealHash != bytes32(0), "deal hash must be non-zero");
        require(_requesterId != bytes32(0), "requester ID must be non-zero");
        require(_respondentId != bytes32(0), "respondent ID must be non-zero");
        require(keccak256(abi.encodePacked(_requesterId)) != keccak256(abi.encodePacked(_respondentId)),
            "requester and respondent must be different");
        require(_amountToStake >= minStake, "amount to stake must be greater or equal to min.stake");

        uint256 requesterAllowance = token.allowance(msg.sender, address(this));
        require(requesterAllowance >= _amountToStake, "allowance too small");
        token.safeTransferFrom(msg.sender, address(this), _amountToStake);

        Claim memory claim = Claim({
            state : State.AwaitingAcceptance,
            modified : now,
            dealId : _dealId,
            dealHash : _dealHash,
            reasonNote : _reasonNote,
            requesterId : _requesterId,
            requesterAddress : msg.sender,
            requesterStaked : _amountToStake,
            respondentId : _respondentId,
            respondentAddress : address(0),
            respondentStaked : 0,
            resolutionNote : ""
            });
        claims.push(claim);

        emit ClaimCreated(_dealId, claims.length - 1);
    }

     
    function accept(uint256 _claimIdx) external whenNotPaused {
        require(_claimIdx < claims.length, "invalid claim index");
        Claim storage claim = claims[_claimIdx];
        require(State.AwaitingAcceptance == claim.state, "State.AwaitingAcceptance required");
        require(msg.sender != claim.requesterAddress, "requester and respondent addresses must be different");

        uint256 requesterStaked = claim.requesterStaked;
        token.safeTransferFrom(msg.sender, address(this), requesterStaked);

        claim.state = State.AwaitingResolution;
        claim.modified = now;
        claim.respondentAddress = msg.sender;
        claim.respondentStaked = requesterStaked;

        emit ClaimAccepted(claim.dealId, _claimIdx);
    }

     
    function resolve(uint256 _claimIdx, string _resolutionNote) external whenNotPaused {
        require(_claimIdx < claims.length, "invalid claim index");
        require(bytes(_resolutionNote).length > 0, "resolution note must not be empty");
        Claim storage claim = claims[_claimIdx];
        require(State.AwaitingResolution == claim.state, "State.AwaitingResolution required");
        require(msg.sender == claim.respondentAddress, "awaiting respondent");

        uint256 respStakedBefore = claim.respondentStaked;

        claim.state = State.AwaitingConfirmation;
        claim.modified = now;
        claim.respondentStaked = 0;
        claim.resolutionNote = _resolutionNote;

        token.safeTransfer(msg.sender, respStakedBefore);

        emit ClaimResolved(claim.dealId, _claimIdx);
    }

     
    function close(uint256 _claimIdx) external whenNotPaused {
        require(_claimIdx < claims.length, "invalid claim index");
        State state = claims[_claimIdx].state;

        if (State.AwaitingAcceptance == state) {
            return _closeAfterAwaitingAcceptance(_claimIdx);
        } else if (State.AwaitingResolution == state) {
            return _closeAfterAwaitingResolution(_claimIdx);
        } else if (State.AwaitingConfirmation == state) {
            return _closeAfterAwaitingConfirmation(_claimIdx);
        }

        revert("claim.State");
    }

    function _closeAfterAwaitingAcceptance(uint256 _claimIdx) internal {
        Claim storage claim = claims[_claimIdx];
        require(msg.sender == claim.requesterAddress, "awaiting requester");
        require(State.AwaitingAcceptance == claim.state, "State.AwaitingAcceptance required");
        require(_hoursPassed(claim.modified, 72), "expiration required");

        uint256 stakedBefore = claim.requesterStaked;

        claim.state = State.ClosedAfterAcceptanceExpired;
        claim.modified = now;
        claim.requesterStaked = 0;

        token.safeTransfer(msg.sender, stakedBefore);

        emit ClaimClosedAfterAcceptanceExpired(claim.dealId, _claimIdx);
    }

    function _closeAfterAwaitingResolution(uint256 _claimIdx) internal {
        Claim storage claim = claims[_claimIdx];
        require(State.AwaitingResolution == claim.state, "State.AwaitingResolution required");
        require(_hoursPassed(claim.modified, 72), "expiration required");
        require(msg.sender == claim.requesterAddress, "awaiting requester");

        uint256 totalStaked = claim.requesterStaked.add(claim.respondentStaked);

        claim.state = State.ClosedAfterResolutionExpired;
        claim.modified = now;
        claim.requesterStaked = 0;
        claim.respondentStaked = 0;

        token.safeTransfer(msg.sender, totalStaked);

        emit ClaimClosedAfterResolutionExpired(claim.dealId, _claimIdx);
    }

    function _closeAfterAwaitingConfirmation(uint256 _claimIdx) internal {
        Claim storage claim = claims[_claimIdx];
        require(msg.sender == claim.requesterAddress, "awaiting requester");
        require(State.AwaitingConfirmation == claim.state, "State.AwaitingConfirmation required");

        bool expired = _hoursPassed(claim.modified, 24);
        if (expired) {
            claim.state = State.ClosedAfterConfirmationExpired;
        } else {
            claim.state = State.Closed;
        }
        claim.modified = now;

        uint256 stakedBefore = claim.requesterStaked;
        claim.requesterStaked = 0;

        token.safeTransfer(msg.sender, stakedBefore);

        if (expired) {
            emit ClaimClosedAfterConfirmationExpired(claim.dealId, _claimIdx);
        } else {
            emit ClaimClosed(claim.dealId, _claimIdx);
        }
    }

    function _hoursPassed(uint256 start, uint256 hoursAfter) internal view returns (bool) {
        return now >= start + hoursAfter * 1 hours;
    }

    function _setMinStake(uint256 _newMinStake) internal {
        uint256 previousMinStake = minStake;
        if (previousMinStake != _newMinStake) {
            emit MinStakeUpdated(previousMinStake, _newMinStake);
            minStake = _newMinStake;
        }
    }
}
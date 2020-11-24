 

pragma solidity ^0.4.21;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract InstantListing is Ownable {
    using SafeMath for uint256;

    struct Proposal {
        uint256 totalContributions;
        mapping(address => uint256) contributions;

        address tokenAddress;
        string projectName;
        string websiteUrl;
        string whitepaperUrl;
        string legalDocumentUrl;
        uint256 icoStartDate;
        uint256 icoEndDate;
        uint256 icoRate;  
        uint256 totalRaised;
    }

     
    uint256 public round;

     
    bool public ranked;

     
    address public beneficiary;

     
    address public paymentTokenAddress;

     
    uint256 public requiredDownPayment;

     
    mapping(uint256 => mapping(address => Proposal)) public proposals;

     
    mapping(uint256 => uint256) public roundContribution;

     
    mapping(address => bool) public listed;

     
     
    mapping(address => uint256) public refundable;

     
    address[] public candidates;

     
    uint256 public startTime;
    uint256 public prevEndTime;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public duration;
    uint256 public numListed;

     
    event SoftCapReached(uint256 indexed _round, address _tokenAddress);
    event TokenProposed(uint256 indexed _round, address _tokenAddress, uint256 _refundEndTime);
    event TokenListed(uint256 indexed _round, address _tokenAddress, uint256 _refundEndTime);
    event Vote(uint256 indexed _round, address indexed _tokenAddress, address indexed voter, uint256 amount);
    event RoundFinalized(uint256 _round);

    constructor() public {
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function initialize(
        address _beneficiary,
        address _paymentTokenAddress)
        onlyOwner public {

        beneficiary = _beneficiary;
        paymentTokenAddress = _paymentTokenAddress;
    }

    function reset(
        uint256 _requiredDownPayment,
        uint256 _startTime,
        uint256 _duration,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _numListed)
        onlyOwner public {
        require(getCurrentTimestamp() >= startTime + duration);


         
        if (!ranked) {
            listTokenByRank();
        }

         
         
        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        if (round != 0) {
            prevEndTime = startTime + duration;
            paymentToken.transfer(beneficiary,
                paymentToken.balanceOf(this) - roundContribution[round]);
        }

        requiredDownPayment = _requiredDownPayment;
        startTime = _startTime;
        duration = _duration;
        hardCap = _hardCap;
        softCap = _softCap;
        numListed = _numListed;
        ranked = false;

        emit RoundFinalized(round);

        delete candidates;

        round += 1;
    }

    function propose(
        address _tokenAddress,
        string _projectName,
        string _websiteUrl,
        string _whitepaperUrl,
        string _legalDocumentUrl,
        uint256 _icoStartDate,
        uint256 _icoEndDate,
        uint256 _icoRate,
        uint256 _totalRaised) public {
        require(proposals[round][_tokenAddress].totalContributions == 0);
        require(getCurrentTimestamp() < startTime + duration);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        uint256 downPayment = paymentToken.allowance(msg.sender, this);

        if (downPayment < requiredDownPayment) {
            revert();
        }

        paymentToken.transferFrom(msg.sender, this, downPayment);

        proposals[round][_tokenAddress] = Proposal({
            tokenAddress: _tokenAddress,
            projectName: _projectName,
            websiteUrl: _websiteUrl,
            whitepaperUrl: _whitepaperUrl,
            legalDocumentUrl: _legalDocumentUrl,
            icoStartDate: _icoStartDate,
            icoEndDate: _icoEndDate,
            icoRate: _icoRate,
            totalRaised: _totalRaised,
            totalContributions: 0
        });

         
        proposals[round][_tokenAddress].contributions[msg.sender] =
            downPayment - requiredDownPayment;
        proposals[round][_tokenAddress].totalContributions = downPayment;
        roundContribution[round] = roundContribution[round].add(
            downPayment - requiredDownPayment);
        listed[_tokenAddress] = false;

        if (downPayment >= softCap && downPayment < hardCap) {
            candidates.push(_tokenAddress);
            emit SoftCapReached(round, _tokenAddress);
        }

        if (downPayment >= hardCap) {
            listed[_tokenAddress] = true;
            emit TokenListed(round, _tokenAddress, refundable[_tokenAddress]);
        }

        refundable[_tokenAddress] = startTime + duration + 7 * 1 days;
        emit TokenProposed(round, _tokenAddress, refundable[_tokenAddress]);
    }

    function vote(address _tokenAddress) public {
        require(getCurrentTimestamp() >= startTime &&
                getCurrentTimestamp() < startTime + duration);
        require(proposals[round][_tokenAddress].totalContributions > 0);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        bool prevSoftCapReached =
            proposals[round][_tokenAddress].totalContributions >= softCap;
        uint256 allowedPayment = paymentToken.allowance(msg.sender, this);

        paymentToken.transferFrom(msg.sender, this, allowedPayment);
        proposals[round][_tokenAddress].contributions[msg.sender] =
            proposals[round][_tokenAddress].contributions[msg.sender].add(
                allowedPayment);
        proposals[round][_tokenAddress].totalContributions =
            proposals[round][_tokenAddress].totalContributions.add(
                allowedPayment);
        roundContribution[round] = roundContribution[round].add(allowedPayment);

        if (!prevSoftCapReached &&
            proposals[round][_tokenAddress].totalContributions >= softCap &&
            proposals[round][_tokenAddress].totalContributions < hardCap) {
            candidates.push(_tokenAddress);
            emit SoftCapReached(round, _tokenAddress);
        }

        if (proposals[round][_tokenAddress].totalContributions >= hardCap) {
            listed[_tokenAddress] = true;
            refundable[_tokenAddress] = 0;
            emit TokenListed(round, _tokenAddress, refundable[_tokenAddress]);
        }

        emit Vote(round, _tokenAddress, msg.sender, allowedPayment);
    }

    function setRefundable(address _tokenAddress, uint256 endTime)
        onlyOwner public {
        refundable[_tokenAddress] = endTime;
    }

     
    function withdrawBalance() onlyOwner public {
        require(getCurrentTimestamp() >= (prevEndTime + 7 * 1 days));

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        paymentToken.transfer(beneficiary, paymentToken.balanceOf(this));
    }

    function refund(address _tokenAddress) public {
        require(refundable[_tokenAddress] > 0 &&
                prevEndTime > 0 &&
                getCurrentTimestamp() >= prevEndTime &&
                getCurrentTimestamp() < refundable[_tokenAddress]);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);

        uint256 amount = proposals[round][_tokenAddress].contributions[msg.sender];
        if (amount > 0) {
            proposals[round][_tokenAddress].contributions[msg.sender] = 0;
            proposals[round][_tokenAddress].totalContributions =
                proposals[round][_tokenAddress].totalContributions.sub(amount);
            paymentToken.transfer(msg.sender, amount);
        }
    }

    function listTokenByRank() onlyOwner public {
        require(getCurrentTimestamp() >= startTime + duration &&
                !ranked);

        quickSort(0, candidates.length);

        uint collected = 0;
        for (uint i = 0; i < candidates.length && collected < numListed; i++) {
            if (!listed[candidates[i]]) {
                listed[candidates[i]] = true;
                refundable[candidates[i]] = 0;
                emit TokenListed(round, candidates[i], refundable[candidates[i]]);
                collected++;
            }
        }

        ranked = true;
    }

    function quickSort(uint beg, uint end) internal {
        if (beg + 1 >= end)
            return;

        uint pv = proposals[round][candidates[end - 1]].totalContributions;
        uint partition = beg;

        for (uint i = beg; i < end; i++) {
            if (proposals[round][candidates[i]].totalContributions > pv) {
                (candidates[partition], candidates[i]) =
                    (candidates[i], candidates[partition]);
                partition++;
            }
        }
        (candidates[partition], candidates[end - 1]) =
           (candidates[end - 1], candidates[partition]);

        quickSort(beg, partition);
        quickSort(partition + 1, end);
    }

    function getContributions(
        uint256 _round,
        address _tokenAddress,
        address contributor) view public returns (uint256) {
        return proposals[_round][_tokenAddress].contributions[contributor];
    }

    function numCandidates() view public returns (uint256) {
        return candidates.length;
    }

    function kill() public onlyOwner {
        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        paymentToken.transfer(beneficiary, paymentToken.balanceOf(this));

        selfdestruct(beneficiary);
    }

     
    function () public payable {
        revert();
    }
}
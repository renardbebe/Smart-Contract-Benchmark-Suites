 

pragma solidity ^0.4.13;

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

contract BbillerBallot is Ownable {
    BbillerToken public token;
    mapping(uint => Issue) public issues;

    uint issueDoesNotExistFlag = 0;
    uint issueVotingFlag = 1;
    uint issueAcceptedFlag = 2;
    uint issueRejectedFlag = 3;

    struct Issue {
        uint votingStartDate;
        uint votingEndDate;
        mapping(address => bool) isVoted;
        uint forCounter;
        uint againstCounter;
        uint flag;
    }

    event CreateIssue(uint _issueId, uint _votingStartDate, uint _votingEndDate, address indexed creator);
    event Vote(uint issueId, bool forVote, address indexed voter);
    event IssueAccepted(uint issueId);
    event IssueRejected(uint issueId);

    function BbillerBallot(BbillerToken _token) public {
        token = _token;
    }

    function createIssue(uint issueId, uint _votingStartDate, uint _votingEndDate) public onlyOwner {
        require(issues[issueId].flag == issueDoesNotExistFlag);

        Issue memory issue = Issue(
            {votingEndDate : _votingEndDate,
            votingStartDate : _votingStartDate,
            forCounter : 0,
            againstCounter : 0,
            flag : issueVotingFlag});
        issues[issueId] = issue;

        CreateIssue(issueId, _votingStartDate, _votingEndDate, msg.sender);
    }

    function vote(uint issueId, bool forVote) public {
        require(token.isTokenUser(msg.sender));

        Issue storage issue = issues[issueId];
        require(!issue.isVoted[msg.sender]);
        require(issue.flag == issueVotingFlag);
        require(issue.votingEndDate > now);
        require(issue.votingStartDate < now);

        issue.isVoted[msg.sender] = true;
        if (forVote) {
            issue.forCounter++;
        }
        else {
            issue.againstCounter++;
        }
        Vote(issueId, forVote, msg.sender);

        uint tokenUserCounterHalf = getTokenUserCounterHalf();
        if (issue.forCounter >= tokenUserCounterHalf) {
            issue.flag = issueAcceptedFlag;
            IssueAccepted(issueId);
        }
        if (issue.againstCounter >= tokenUserCounterHalf) {
            issue.flag = issueRejectedFlag;
            IssueRejected(issueId);
        }
    }

    function getVoteResult(uint issueId) public view returns (string) {
        Issue storage issue = issues[issueId];
        if (issue.flag == issueVotingFlag) {
            return 'Voting';
        }
        if (issue.flag == issueAcceptedFlag) {
            return 'Accepted';
        }
        if (issue.flag == issueRejectedFlag) {
            return 'Rejected';
        }
        if (issue.flag == issueDoesNotExistFlag) {
            return 'DoesNotExist';
        }
    }

    function getTokenUserCounterHalf() internal returns (uint) {
         
        uint half = 2;
        uint tokenUserCounter = token.getTokenUserCounter();
        uint tokenUserCounterHalf = tokenUserCounter / half;
        if (tokenUserCounterHalf * half != tokenUserCounter) {
             
            tokenUserCounterHalf++;
        }
        return tokenUserCounterHalf;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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
  event Mint(address indexed _to, uint256 _amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
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

contract BbillerToken is MintableToken {
    string public symbol = 'BBILLER';
    uint public decimals = 18;
    uint public tokenUserCounter;   

    mapping(address => bool) public isTokenUser;

    event CountTokenUser(address _tokenUser, uint _tokenUserCounter, bool increment);

    function getTokenUserCounter() public view returns (uint) {
        return tokenUserCounter;
    }

    function countTokenUser(address tokenUser) internal {
        if (!isTokenUser[tokenUser]) {
            isTokenUser[tokenUser] = true;
            tokenUserCounter++;
        }
        CountTokenUser(tokenUser, tokenUserCounter, true);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        bool res = super.transfer(to, value);
        countTokenUser(to);
        return res;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bool res = super.transferFrom(from, to, value);
        countTokenUser(to);
        if (balanceOf(from) <= 0) {
            isTokenUser[from] = false;
            tokenUserCounter--;
            CountTokenUser(from, tokenUserCounter, false);
        }
        return res;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        bool res = super.mint(_to, _amount);
        countTokenUser(_to);
        return res;
    }
}
 

pragma solidity 0.4.18;

 

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}




 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  event Mint(address indexed to, uint256 amount);
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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}



contract VITToken is Claimable, HasNoTokens, MintableToken {
     
    string public constant name = "Vice";
    string public constant symbol = "VIT";
    uint8 public constant decimals = 18;
     

    modifier cannotMint() {
        require(mintingFinished);
        _;
    }

    function VITToken() public {

    }

     
     
     
    function transfer(address _to, uint256 _value) public cannotMint returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public cannotMint returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}




 
contract VITTokenSale is Claimable {
    using Math for uint256;
    using SafeMath for uint256;

     
    VITToken public vitToken;

     
    address public fundingRecipient;

     
    uint256 public constant TOKEN_UNIT = 10 ** 18;

     
    uint256 public constant MAX_TOKENS_SOLD = 2 * 10 ** 9 * TOKEN_UNIT;

     
    uint256 public vitPerWei;

     
    uint256 public constant RESTRICTED_PERIOD_DURATION = 1 days;
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public refundEndTime;
    mapping (address => uint256) public refundableEther;
    mapping (address => uint256) public claimableTokens;
    uint256 public totalClaimableTokens = 0;
    bool public finalizedRefund = false;

     
    uint256 public tokensSold = 0;

     
    mapping (address => uint256) public participationHistory;

     
    mapping (address => uint256) public participationCaps;

     
    address[20] public strategicPartnersPools;
    uint256 public constant STRATEGIC_PARTNERS_POOL_ALLOCATION = 100 * 10 ** 6 * TOKEN_UNIT;  

    event TokensIssued(address indexed to, uint256 tokens);
    event EtherRefunded(address indexed from, uint256 weiAmount);
    event TokensClaimed(address indexed from, uint256 tokens);
    event Finalized();
    event FinalizedRefunds();

     
    modifier onlyDuringSale() {
        require(!saleEnded() && now >= startTime);

        _;
    }

     
    modifier onlyAfterSale() {
        require(saleEnded());

        _;
    }

     
    modifier onlyDuringRefund() {
        require(saleDuringRefundPeriod());

        _;
    }

    modifier onlyAfterRefund() {
        require(saleAfterRefundPeriod());

        _;
    }

     
     
     
     
     
     
     
    function VITTokenSale(address _fundingRecipient, uint256 _startTime, uint256 _endTime, uint256 _refundEndTime,
        uint256 _vitPerWei, address[20] _strategicPartnersPools) public {
        require(_fundingRecipient != address(0));
        require(_startTime > now && _startTime < _endTime && _endTime < _refundEndTime);
        require(_startTime.add(RESTRICTED_PERIOD_DURATION) < _endTime);
        require(_vitPerWei > 0);

        for (uint i = 0; i < _strategicPartnersPools.length; ++i) {
            require(_strategicPartnersPools[i] != address(0));
        }

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = _endTime;
        refundEndTime = _refundEndTime;
        vitPerWei = _vitPerWei;
        strategicPartnersPools = _strategicPartnersPools;

         
        vitToken = new VITToken();

         
        grantInitialAllocations();
    }

     
    function () external payable onlyDuringSale {
        address recipient = msg.sender;

        uint256 cappedWeiReceived = msg.value;
        uint256 weiAlreadyParticipated = participationHistory[recipient];

         
        if (saleDuringRestrictedPeriod()) {
            uint256 participationCap = participationCaps[recipient];
            cappedWeiReceived = Math.min256(cappedWeiReceived, participationCap.sub(weiAlreadyParticipated));
        }

        require(cappedWeiReceived > 0);

         
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 weiLeftInSale = tokensLeftInSale.div(vitPerWei);
        uint256 weiToParticipate = Math.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[recipient] = weiAlreadyParticipated.add(weiToParticipate);

         
        uint256 tokensToIssue = weiToParticipate.mul(vitPerWei);
        if (tokensLeftInSale.sub(tokensToIssue) < vitPerWei) {
             
             
            tokensToIssue = tokensLeftInSale;
        }

         
        refundableEther[recipient] = refundableEther[recipient].add(weiToParticipate);
        claimableTokens[recipient] = claimableTokens[recipient].add(tokensToIssue);

         
        totalClaimableTokens = totalClaimableTokens.add(tokensToIssue);
        tokensSold = tokensSold.add(tokensToIssue);

         
        issueTokens(address(this), tokensToIssue);

         
        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

     
     
     
    function setRestrictedParticipationCap(address[] _participants, uint256 _cap) external onlyOwner {
        for (uint i = 0; i < _participants.length; ++i) {
            participationCaps[_participants[i]] = _cap;
        }
    }

     
    function finalize() external onlyAfterSale {
         
        if (tokensSold < MAX_TOKENS_SOLD) {
            issueTokens(fundingRecipient, MAX_TOKENS_SOLD.sub(tokensSold));
        }

         
        vitToken.finishMinting();

        Finalized();
    }

    function finalizeRefunds() external onlyAfterRefund {
        require(!finalizedRefund);

        finalizedRefund = true;

         
        fundingRecipient.transfer(this.balance);

        FinalizedRefunds();
    }

     
     
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        if (token == vitToken) {
            balance = balance.sub(totalClaimableTokens);
        }

        assert(token.transfer(owner, balance));
    }

     
     
    function claimTokens(uint256 _tokensToClaim) public onlyAfterSale {
        require(_tokensToClaim != 0);

        address participant = msg.sender;
        require(claimableTokens[participant] > 0);

        uint256 claimableTokensAmount = claimableTokens[participant];
        require(_tokensToClaim <= claimableTokensAmount);

        uint256 refundableEtherAmount = refundableEther[participant];
        uint256 etherToClaim = _tokensToClaim.mul(refundableEtherAmount).div(claimableTokensAmount);
        assert(etherToClaim > 0);

        refundableEther[participant] = refundableEtherAmount.sub(etherToClaim);
        claimableTokens[participant] = claimableTokensAmount.sub(_tokensToClaim);
        totalClaimableTokens = totalClaimableTokens.sub(_tokensToClaim);

         
        assert(vitToken.transfer(participant, _tokensToClaim));

         
        if (!finalizedRefund) {
            fundingRecipient.transfer(etherToClaim);
        }

        TokensClaimed(participant, _tokensToClaim);
    }

     
    function claimAllTokens() public onlyAfterSale {
        uint256 claimableTokensAmount = claimableTokens[msg.sender];
        claimTokens(claimableTokensAmount);
    }

     
     
    function refundEther(uint256 _etherToClaim) public onlyDuringRefund {
        require(_etherToClaim != 0);

        address participant = msg.sender;

        uint256 refundableEtherAmount = refundableEther[participant];
        require(_etherToClaim <= refundableEtherAmount);

        uint256 claimableTokensAmount = claimableTokens[participant];
        uint256 tokensToClaim = _etherToClaim.mul(claimableTokensAmount).div(refundableEtherAmount);
        assert(tokensToClaim > 0);

        refundableEther[participant] = refundableEtherAmount.sub(_etherToClaim);
        claimableTokens[participant] = claimableTokensAmount.sub(tokensToClaim);
        totalClaimableTokens = totalClaimableTokens.sub(tokensToClaim);

         
        assert(vitToken.transfer(fundingRecipient, tokensToClaim));

         
        participant.transfer(_etherToClaim);

        EtherRefunded(participant, _etherToClaim);
    }

     
    function refundAllEther() public onlyDuringRefund {
        uint256 refundableEtherAmount = refundableEther[msg.sender];
        refundEther(refundableEtherAmount);
    }

     
    function grantInitialAllocations() private onlyOwner {
        for (uint i = 0; i < strategicPartnersPools.length; ++i) {
            issueTokens(strategicPartnersPools[i], STRATEGIC_PARTNERS_POOL_ALLOCATION);
        }
    }

     
     
     
    function issueTokens(address _recipient, uint256 _tokens) private {
         
        assert(vitToken.mint(_recipient, _tokens));

        TokensIssued(_recipient, _tokens);
    }

     
     
    function saleEnded() private view returns (bool) {
        return tokensSold >= MAX_TOKENS_SOLD || now >= endTime;
    }

     
     
     
     
    function saleDuringRestrictedPeriod() private view returns (bool) {
        return now <= startTime.add(RESTRICTED_PERIOD_DURATION);
    }

     
     
    function saleDuringRefundPeriod() private view returns (bool) {
        return saleEnded() && now <= refundEndTime;
    }

     
     
    function saleAfterRefundPeriod() private view returns (bool) {
        return saleEnded() && now > refundEndTime;
    }
}
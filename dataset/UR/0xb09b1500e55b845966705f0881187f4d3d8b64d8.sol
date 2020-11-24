 

 

pragma solidity 0.5.8;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    ERC20Basic public token;
    address public beneficiary;
    uint64 public releaseTime;

    function tokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
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
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owned() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }
}

contract MountableToken is StandardToken, Owned, BurnableToken {
    string public constant name = "Mountable Token";
    string public constant symbol = "MNT";
    uint8 public constant decimals = 15;

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 750000000000000000000000;  

     
    uint256 public constant BASE_RATE = 325000;

     
     
     
    uint64 private constant dateHOTSale = 1562407200 - 7 hours;
    
     
    uint64 private constant preSale = 1563012000 - 7 hours;

     
    uint64 private constant tokenSale1 = 1563616800 - 7 hours;

     
    uint64 private constant tokenSale2 = 1564826400 - 7 hours;

     
    uint64 private constant tokenSale3 = 1566036000 - 7 hours;

     
    uint64 private constant endDate = 1567245600 - 7 hours;

     
    uint256[5] private roundCaps = [
        100000000000000000000000,  
        200000000000000000000000,  
        350000000000000000000000,  
        550000000000000000000000,  
        750000000000000000000000  
    ];
    uint8[5] private roundDiscountPercentages = [50, 33, 25, 12, 6];

     
    uint64 private constant dateTeamTokensLockedTill = 1598868000 - 7 hours;

     
    bool public tokenSaleClosed = false;

     
    address public timelockContractAddress;

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
            && !tokenSaleClosed && now >= dateHOTSale);
        _;
    }

     
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    modifier tradingOpen {
        require(tokenSaleClosed);
        _;
    }

     
     
    function () external payable {
        purchaseTokens(msg.sender);
    }

     
     
    function purchaseTokens(address _beneficiary) public payable inProgress {
        require(msg.value >= 0.05 ether);

        uint256 tokens = computeTokenAmount(msg.value);

        require(totalSupply.add(tokens) <= TOKENS_SALE_HARD_CAP);

        doIssueTokens(_beneficiary, tokens);
        owner.transfer(address(this).balance);

    }

     
     
     
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner beforeEnd {
        doIssueTokens(_beneficiary, _tokens);
    }

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

        totalSupply = totalSupply.add(_tokens);
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

        emit Transfer(address(0), _beneficiary, _tokens);
    }

     
    function price() public view returns (uint256 tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = (ethAmount.mul(BASE_RATE)/10000000000000)*10000000000;
        uint8 roundNum = currentRoundIndex();
        tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum]));
        while(tokens.add(totalSupply) > roundCaps[roundNum] && roundNum < 4){
           roundNum++;
           tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum]));
        }
    }

     
     
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

         
        while(roundNum < 4 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

     
     
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= endDate);
        if(now > tokenSale3) return 4;
        if(now > tokenSale2) return 3;
        if(now > tokenSale1) return 2;
        if(now > preSale) return 1;
        else return 0;
    }

     
    function close() public onlyOwner beforeEnd {
         
         
        uint256 lockedTokens = 120000000000000000000000;
         
        uint256 partnerTokens = 130000000000000000000000;

        issueLockedTokens(lockedTokens);
        issuePartnerTokens(partnerTokens);

        totalSupply = totalSupply.add(lockedTokens+partnerTokens);

         
        tokenSaleClosed = true;

        owner.transfer(address(this).balance);
        
    }

     
    function issueLockedTokens( uint lockedTokens) internal{
         
        TokenTimelock lockedTeamTokens = new TokenTimelock();
        lockedTeamTokens.tokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
         
        emit Transfer(address(0), timelockContractAddress, lockedTokens);

    }

     
    function issuePartnerTokens(uint partnerTokens) internal{
        balances[owner] = partnerTokens;
        emit Transfer(address(0), owner, partnerTokens);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }

}
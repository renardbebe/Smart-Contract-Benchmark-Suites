 

pragma solidity 0.4.18;

 
 


interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract FwPermissions {

  address public admin;
  address public backupAdmin;
   
  address public reserve;
  bool public timePeriodsSet;
  bool public adminStaked;
  bool public endBalanceLogged;
  mapping (address => bool) public isContributor;
  mapping (address => bool) public hasClaimed;
  address[] public contributors;
   
  uint public start;
  uint public adminP;
  uint public raiseP;
  uint public opperateP;
  uint public liquidP;

  function FwPermissions() public {
        admin = msg.sender;
  }

   
  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }

  modifier onlyBackupAdmin() {
      require(msg.sender == backupAdmin);
      _;
  }

  modifier timePeriodsNotSet() {
      require(timePeriodsSet == false);
      _;
  }

  modifier timePeriodsAreSet() {
      require(timePeriodsSet == true);
      _;
  }

  modifier onlyReserve() {
      require(msg.sender == reserve);
      _;
  }

  modifier onlyContributor() {
      require(isContributor[msg.sender]);
      _;
  }

  modifier adminHasStaked() {
      require(adminStaked == true);
      _;
  }

  modifier adminHasNotStaked() {
      require(adminStaked == false);
      _;
  }

  modifier endBalanceNotLogged() {
      require(endBalanceLogged == false);
      _;
  }

  modifier endBalanceIsLogged() {
      require(endBalanceLogged == true);
      _;
  }

  modifier hasNotClaimed() {
      require(!hasClaimed[msg.sender]);
      _;
  }

  modifier inAdminP() {
      require(now < (start + adminP));
      _;
  }

  modifier inRaiseP() {
      require(now < (start + adminP + raiseP) && now > (start + adminP));
      _;
  }

  modifier inOpperateP() {
      require(now < (start + adminP + raiseP + opperateP) && now > (start + adminP + raiseP));
      _;
  }

  modifier inLiquidP() {
      require(now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP + opperateP));
      _;
  }

  modifier inOpAndLiqP() {
      require(now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP));
      _;
  }

  modifier inClaimP() {
      require(now > (start + adminP + raiseP + opperateP + liquidP));
      _;
  }
}


contract FundWallet is FwPermissions {

    uint public adminStake;
    uint public raisedBalance;
    uint public endBalance;
    mapping (address => uint) public stake;
     
    uint public adminCarry;  
    
     
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

     
    event ContributorAdded(address _contributor);
    event ContributorRemoval(address _contributor);
    event ContributorDeposit(address sender, uint value);
    event ContributorDepositReturn(address _contributor, uint value);
    event AdminDeposit(address sender, uint value);
    event AdminDepositReturned(address sender, uint value);
    event TokenPulled(ERC20 token, uint amount, address sendTo);
    event EtherPulled(uint amount, address sendTo);
    event TokenWithdraw(ERC20 token, uint amount, address sendTo);
    event EtherWithdraw(uint amount, address sendTo);


     
     
     
    function FundWallet(address _admin, address _backupAdmin) public {
        require(_admin != address(0));
        require(_backupAdmin != address(0));
        admin = _admin;
        backupAdmin = _backupAdmin;
    }

     
     
     
    function setFundScheme(uint _adminStake, uint _adminCarry) public onlyAdmin inAdminP timePeriodsAreSet {
        require(_adminStake > 0);
        adminStake = _adminStake;
        adminCarry = _adminCarry;  
    }

     
     
     
     
     
    function setTimePeriods(uint _adminP, uint _raiseP, uint _opperateP, uint _liquidP) public onlyAdmin timePeriodsNotSet {
        start = now;
        adminP = _adminP * (60 minutes);
        raiseP = _raiseP * (60 minutes);
        opperateP = _opperateP * (60 minutes);
        liquidP = _liquidP * (60 minutes);
        timePeriodsSet = true;
    }

     
     
    function setReserve (address _reserve) public onlyAdmin inAdminP timePeriodsAreSet {
        reserve = _reserve;
    }

     
    function() public payable {
    }

     
     
     
    function changeAdmin(address _newAdmin) public onlyBackupAdmin {
        admin = _newAdmin;
    }

     
     
     
    function addContributor(address _contributor) public onlyAdmin inAdminP timePeriodsAreSet {
        require(!isContributor[ _contributor]);  
        require(_contributor != admin);
        isContributor[ _contributor] = true;
        contributors.push( _contributor);
        ContributorAdded( _contributor);
    }

     
     
     
    function removeContributor(address _contributor) public onlyAdmin inAdminP timePeriodsAreSet {
        require(isContributor[_contributor]);
        isContributor[_contributor] = false;
        for (uint i=0; i < contributors.length - 1; i++)
            if (contributors[i] == _contributor) {
                contributors[i] = contributors[contributors.length - 1];
                break;
            }
        contributors.length -= 1;
        ContributorRemoval(_contributor);
    }

     
    function getContributors() public constant returns (address[]){
        return contributors;
    }

     
     
    function contributorDeposit() public timePeriodsAreSet onlyContributor adminHasStaked inRaiseP payable {
        if (adminStake >= msg.value && msg.value > 0 && stake[msg.sender] < adminStake) {
            raisedBalance += msg.value;
            stake[msg.sender] += msg.value;
            ContributorDeposit(msg.sender, msg.value);
        }
        else {
            revert();
        }
    }

     
     
    function contributorRefund() public timePeriodsAreSet onlyContributor inRaiseP {
        isContributor[msg.sender] = false;
        for (uint i=0; i < contributors.length - 1; i++)
            if (contributors[i] == msg.sender) {
                contributors[i] = contributors[contributors.length - 1];
                break;
            }
        contributors.length -= 1;
        ContributorRemoval(msg.sender);

        if (stake[msg.sender] > 0) {
            msg.sender.transfer(stake[msg.sender]);
            raisedBalance -= stake[msg.sender];
            delete stake[msg.sender];
            ContributorDepositReturn(msg.sender, stake[msg.sender]);
        }
    }

     
     
    function adminDeposit() public timePeriodsAreSet onlyAdmin adminHasNotStaked inRaiseP payable {
        if (msg.value == adminStake) {
            raisedBalance += msg.value;
            stake[msg.sender] += msg.value;
            adminStaked = true;
            AdminDeposit(msg.sender, msg.value);
        }
        else {
            revert();
        }
    }

     
     
    function adminRefund() public timePeriodsAreSet onlyAdmin adminHasStaked inRaiseP {
        require(raisedBalance == adminStake);
        admin.transfer(adminStake);
        adminStaked = false;
        raisedBalance -= adminStake;
        AdminDepositReturned(msg.sender, adminStake);
    }

     
     
    function withdrawToken(ERC20 token, uint amount, address sendTo) external timePeriodsAreSet onlyAdmin inOpperateP {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

     
     
    function withdrawEther(uint amount, address sendTo) external timePeriodsAreSet onlyAdmin inOpperateP {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }

     
     
    function logEndBal() public inClaimP endBalanceNotLogged timePeriodsAreSet {
        endBalance = address(this).balance;
        endBalanceLogged = true;
    }

     
     
    function adminClaim() public onlyAdmin timePeriodsAreSet inClaimP endBalanceIsLogged hasNotClaimed {
        if (endBalance > raisedBalance) {
            admin.transfer(((endBalance - raisedBalance)*(adminCarry))/10000);  
            admin.transfer(((((endBalance - raisedBalance)*(10000-adminCarry))/10000)*adminStake)/raisedBalance);  
            admin.transfer(adminStake);  
            hasClaimed[msg.sender] = true;
        }
        else {
            admin.transfer((endBalance*adminStake)/raisedBalance);
            hasClaimed[msg.sender] = true;
        }
    }

     
     
    function contributorClaim() public timePeriodsAreSet onlyContributor inClaimP endBalanceIsLogged hasNotClaimed {
        if (endBalance > raisedBalance) {
            msg.sender.transfer(((((endBalance - raisedBalance)*(10000-adminCarry))/10000)*stake[msg.sender])/raisedBalance);  
            msg.sender.transfer(stake[msg.sender]);  
            hasClaimed[msg.sender] = true;
        }
        else {
            msg.sender.transfer((endBalance*stake[msg.sender])/raisedBalance);
            hasClaimed[msg.sender] = true;
        }
    }

     

     
     
    function pullToken(ERC20 token, uint amount) external onlyReserve inOpAndLiqP returns (bool){
        require(token.transfer(reserve, amount));
        TokenPulled(token, amount, reserve);
        return true;
    }

     
    function pullEther(uint amount) external onlyReserve inOpperateP returns (bool){
        reserve.transfer(amount);
        EtherPulled(amount, reserve);
        return true;
    }

     
    function checkBalance(ERC20 token) public view returns (uint) {
        if (now < (start + adminP +raiseP + opperateP) && now > (start + adminP + raiseP)) {
            if (token == ETH_TOKEN_ADDRESS) {
                return this.balance;
            }
            else {
                return token.balanceOf(this);
            }
        }
        if (now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP + opperateP)) {
            if (token == ETH_TOKEN_ADDRESS) {
                return 0;
            }
            else {
                return token.balanceOf(this);
            }
        }
        else return 0;
    }

}
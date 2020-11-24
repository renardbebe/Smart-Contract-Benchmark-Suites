 

pragma solidity ^0.5.0;

contract ETHFlow {
    using SafeMath for uint256;
    
    struct Tariff {
        uint256 id;
        string name;
        uint256 price;
        uint256 time;
        uint256 value;
        uint256 duration;
        uint256 monthly;
    }

    mapping(uint256 => Tariff) public tariffs;
    mapping(address => uint256) public tariffOf;
    mapping(address => uint256) public tariffTime;
    mapping(address => uint256) public time;
    mapping(address => bool) public active;
    mapping(address => uint256) public balanceUser;
    mapping(address => address) public myReferrer;
     
    mapping(address => mapping(address => uint256)) public statistic;
    mapping(address => address[]) public referals;
    mapping(address => uint256) public referalsEarning;
    address payable private admin = 0xc5568a59A56cFe4887fCca38eDA3dF202b8654d0;
    uint256 private adminPercent = 10;
    uint256 private percentFromEachProfit = 20;

    event Deposit(
        address Investor, 
        uint256 Amount
    );

    constructor() public {
        tariffs[1].id = 1;
        tariffs[1].name = 'free';
        tariffs[1].price = 0;
        tariffs[1].time = 3 * 1 hours;                       
        tariffs[1].value = 360 * 1 szabo;           
        tariffs[1].duration = 0;
        tariffs[1].monthly = 108 * 1 finney;     

        tariffs[2].id = 2;
        tariffs[2].name = 'tariff1';
        tariffs[2].price = 50 * 1 finney;        
        tariffs[2].time = 90 * 1 minutes;                      
        tariffs[2].value = 540 * 1 szabo;          
        tariffs[2].duration = 476 * 1 hours;               
        tariffs[2].monthly = 259200 * 1 szabo;     

        tariffs[3].id = 3;
        tariffs[3].name = 'tariff2';
        tariffs[3].price = 100 * 1 finney;       
        tariffs[3].time = 1 hours;                      
        tariffs[3].value = 900 * 1 szabo;          
        tariffs[3].duration = 438 * 1 hours;               
        tariffs[3].monthly = 648 * 1 finney;     

        tariffs[4].id = 4;
        tariffs[4].name = 'tariff3';
        tariffs[4].price = 250 * 1 finney;       
        tariffs[4].time = 225 * 1 minutes;                     
        tariffs[4].value = 9 * 1 finney;         
        tariffs[4].duration = 416 * 1 hours;               
        tariffs[4].monthly = 1728 * 1 finney;    

        tariffs[5].id = 5;
        tariffs[5].name = 'tariff4';
        tariffs[5].price = 1 ether;      
        tariffs[5].time = 35295;                     
        tariffs[5].value = 100 * 1 finney;       
        tariffs[5].duration = 391 * 1 hours;               
        tariffs[5].monthly = 7344 * 1 finney;    

        tariffs[6].id = 6;
        tariffs[6].name = 'tariff5';
        tariffs[6].price = 5 * 1 ether;      
        tariffs[6].time = 66667;                     
        tariffs[6].value = 1 ether;      
        tariffs[6].duration = 15 * 1 days;               
        tariffs[6].monthly = 38880 * 1 ether;   

        tariffs[7].id = 7;
        tariffs[7].name = 'tariff6';
        tariffs[7].price = 25 * 1 ether;     
        tariffs[7].time = 2000 * 1 minutes;                    
        tariffs[7].value = 10 * 1 ether;     
        tariffs[7].duration = 314 * 1 hours;               
        tariffs[7].monthly = 216 * 1 ether;  

        tariffs[8].id = 8;
        tariffs[8].name = 'tariff7';
        tariffs[8].price = 100 * 1 ether;    
        tariffs[8].time = 62500;                     
        tariffs[8].value = 25 * 1 ether;     
        tariffs[8].duration = 11 * 1 days;                
        tariffs[8].monthly = 1036 * 1 ether; 
    }

    function activate(address _referrer) public {
        require(myReferrer[msg.sender] == address(0));
        
        active[msg.sender] = true;
        time[msg.sender] = now;
        tariffOf[msg.sender] = 1;
        
        address referrer = _referrer;

        if(referrer == address(0)) {
            referrer = admin;
        }
    
        myReferrer[msg.sender] = referrer;
            
        referals[referrer].push(msg.sender);
    }

    function getETH() public payable {
        require(active[msg.sender], "Need activate first");

        uint256 userTariff = tariffOf[msg.sender];
        uint256 value;

         
        if(userTariff > 1 && 
            now > tariffTime[msg.sender].add(tariffs[userTariff].duration)
        ) {
            uint256 expire = tariffTime[msg.sender].add(tariffs[userTariff].duration);
            uint256 tariffDuration = expire.sub(time[msg.sender]);
            uint256 defaultDuration = now.sub(expire);

            value = tariffs[userTariff].value
                        .div(tariffs[userTariff].time)
                        .mul(tariffDuration);
            value = value.add(tariffs[1].value
                        .div(tariffs[1].time)
                        .mul(defaultDuration));

            require(value >= tariffs[1].value , "Too early");

            userTariff = 1;
            tariffOf[msg.sender] = 1;
        } else {
            value = getAmountOfEthForWithdrawal();

            require(value >= tariffs[userTariff].value , "Too early");
        }

        uint256 sum = value;
        
        if (myReferrer[msg.sender] != address(0)) {
            uint256 refSum = sum.mul(percentFromEachProfit).div(100);
            balanceUser[myReferrer[msg.sender]] = 
                balanceUser[myReferrer[msg.sender]].add(refSum);
                
            statistic[myReferrer[msg.sender]][msg.sender] =
                statistic[myReferrer[msg.sender]][msg.sender].add(refSum);
            referalsEarning[myReferrer[msg.sender]] = 
                referalsEarning[myReferrer[msg.sender]].add(refSum);
        }
        
        balanceUser[msg.sender] = balanceUser[msg.sender].add(sum);
        time[msg.sender] = now;
    }

    function getAmountOfEthForWithdrawal() public view returns (uint256) {
        uint256 value;
        if(now >= tariffs[tariffOf[msg.sender]].time.add(time[msg.sender])) {
            value = tariffs[tariffOf[msg.sender]].value;
        } else {
            value = now.sub(time[msg.sender])
                .mul(tariffs[tariffOf[msg.sender]].value
                    .div(tariffs[tariffOf[msg.sender]].time));
        }
        
        return value;
    }
    
    function getStatistic(address _refer, address _referal) public view returns (uint256) {
        return statistic[myReferrer[_refer]][_referal];
    }
    
    function getAmountOfReferals() public view returns (uint256) {
        return referals[msg.sender].length;
    }
    
    function getEarnedMonetFromReferals() public view returns (uint256) {
        return referalsEarning[msg.sender];
    }

    function() external payable {
        if(msg.value == 0) {
            getETH();
        } else {
            changeTariff();
        }
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawal() public {
        uint256 value = balanceUser[msg.sender];

        require(value <= address(this).balance, "Not enough ETH on the contract");
        require(value >= 100 * 1 szabo, "Minimum withdrawal 0.0001 ETH");

        balanceUser[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }

    function detectTariffId() public payable returns (uint256) {
        require(msg.value >= tariffs[1].price, "Insufficient funds");

        uint256 found = 0;
        for(uint256 i = 1; i < 8; i++) {
            if(msg.value >= getPriceForNewTariff(i) && 
            msg.value < getPriceForNewTariff(i+1)) {
                found = i;
            }
        }
        if(msg.value >= getPriceForNewTariff(8)) {
            found = 8;
        }
        
        return found;
    }
    
    function getPriceForNewTariff(uint256 _newTariff) public view returns (uint256) {
        if(tariffOf[msg.sender] == 1) {
            return tariffs[_newTariff].price;
        }
        
        uint256 duration = now - time[msg.sender];
        uint256 timeLeft = tariffs[tariffOf[msg.sender]].duration
                    - duration;
                    
        if(timeLeft == 0) {
            return tariffs[_newTariff].price;
        }
        
        uint256 pricePerOneSec = tariffs[tariffOf[msg.sender]].price
                    / tariffs[tariffOf[msg.sender]].duration;
        uint256 moneyLeft = pricePerOneSec * timeLeft * 90 / 100;
        
        return tariffs[_newTariff].price - moneyLeft;
    }
 
    function changeTariff() public payable {
        uint256 id = detectTariffId();

        require(id >= tariffOf[msg.sender]);
        
        uint256 commission = getPriceForNewTariff(id).mul(adminPercent).div(100);
        commission = commission.add(tariffs[id].price
                        .sub(getPriceForNewTariff(id)).mul(100).div(90)
                        .sub(tariffs[id].price.sub(getPriceForNewTariff(id))));

        admin.transfer(commission);
        msg.sender.transfer(msg.value.sub(getPriceForNewTariff(id)));

        if(!active[msg.sender]) {
            active[msg.sender] = true;
        }
        
        time[msg.sender] = now;
        tariffOf[msg.sender] = id;
        tariffTime[msg.sender] = now;
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
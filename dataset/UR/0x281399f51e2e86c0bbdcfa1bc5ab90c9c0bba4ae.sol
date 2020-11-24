 

 

pragma solidity 0.5.8; 

 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
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
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


 

 
 
 
 
 
 
 
 
 
 
 
 



contract DistributionContract is Pausable {
    using SafeMath for uint256;

    uint256 constant public decimals = 1 ether;
    address[] public tokenOwners ;  
    uint256 public TGEDate = 0;  
    uint256 constant public daysLockWhenDaily = 365;
    uint256 constant public month = 30 days;
    uint256 constant public year = 365 days;
    uint256 public lastDateDistribution = 0;
    uint256 public daysPassed = 0;
  
    
    mapping(address => DistributionStep[]) public distributions;  
    
    ERC20 public erc20;

    struct DistributionStep {
        uint256 amountAllocated;
        uint256 currentAllocated;
        uint256 unlockDay;
        uint256 amountSent;
        bool isDaily;
    }
    
    constructor() public{
        
         
        setInitialDistribution(0x9ac2009901a88302D344ba3fA75682919bb7372a, 440000000, year, false);
        setInitialDistribution(0x9ac2009901a88302D344ba3fA75682919bb7372a, 440000000, year.add(3 * month), false);
        setInitialDistribution(0x9ac2009901a88302D344ba3fA75682919bb7372a, 440000000, year.add(6 * month), false);
        setInitialDistribution(0x9ac2009901a88302D344ba3fA75682919bb7372a, 440000000, year.add(9 * month), false);
        setInitialDistribution(0x9ac2009901a88302D344ba3fA75682919bb7372a, 440000000, year.add(12 * month), false);
         
        setInitialDistribution(0x6714d41094a264BB4b8fCB74713B42cFEe6B4F74, 515000000, year, false);
        setInitialDistribution(0x6714d41094a264BB4b8fCB74713B42cFEe6B4F74, 515000000, year.add(3 * month), false);
        setInitialDistribution(0x6714d41094a264BB4b8fCB74713B42cFEe6B4F74, 515000000, year.add(6 * month), false);
        setInitialDistribution(0x6714d41094a264BB4b8fCB74713B42cFEe6B4F74, 515000000, year.add(9 * month), false);
        setInitialDistribution(0x6714d41094a264BB4b8fCB74713B42cFEe6B4F74, 515000000, year.add(12 * month), false);
         
        setInitialDistribution(0x76338947e861bbd44C13C6402cA502DD61f3Fe90, 120000000, 6 * month, false);
        setInitialDistribution(0x76338947e861bbd44C13C6402cA502DD61f3Fe90, 120000000, 9 * month, false);
        setInitialDistribution(0x76338947e861bbd44C13C6402cA502DD61f3Fe90, 120000000, year, false);
        setInitialDistribution(0x76338947e861bbd44C13C6402cA502DD61f3Fe90, 120000000, year.add(3 * month), false);
        setInitialDistribution(0x76338947e861bbd44C13C6402cA502DD61f3Fe90, 120000000, year.add(6 * month), false);
         
        setInitialDistribution(0x59662241cB102B2A49250AE0a4332C1D81f7A35a, 140000000, 6 * month, false);
        setInitialDistribution(0x59662241cB102B2A49250AE0a4332C1D81f7A35a, 140000000, 9 * month, false);
        setInitialDistribution(0x59662241cB102B2A49250AE0a4332C1D81f7A35a, 140000000, year, false);
        setInitialDistribution(0x59662241cB102B2A49250AE0a4332C1D81f7A35a, 140000000, year.add(3 * month), false);
        setInitialDistribution(0x59662241cB102B2A49250AE0a4332C1D81f7A35a, 140000000, year.add(6 * month), false);
         
        setInitialDistribution(0x3cBC0B3e2A45932436ECbe35a4f2f267837BF093, 140000000, 6 * month, false);
        setInitialDistribution(0x3cBC0B3e2A45932436ECbe35a4f2f267837BF093, 140000000, 9 * month, false);
        setInitialDistribution(0x3cBC0B3e2A45932436ECbe35a4f2f267837BF093, 140000000, year, false);
        setInitialDistribution(0x3cBC0B3e2A45932436ECbe35a4f2f267837BF093, 140000000, year.add(3 * month), false);
        setInitialDistribution(0x3cBC0B3e2A45932436ECbe35a4f2f267837BF093, 140000000, year.add(6 * month), false);
         
        setInitialDistribution(0xA91335CC09A4Ab1dFfF466AF5f34f7647c842Fa4, 140000000, 6 * month, false);
        setInitialDistribution(0xA91335CC09A4Ab1dFfF466AF5f34f7647c842Fa4, 140000000, 9 * month, false);
        setInitialDistribution(0xA91335CC09A4Ab1dFfF466AF5f34f7647c842Fa4, 140000000, year, false);
        setInitialDistribution(0xA91335CC09A4Ab1dFfF466AF5f34f7647c842Fa4, 140000000, year.add(3 * month), false);
        setInitialDistribution(0xA91335CC09A4Ab1dFfF466AF5f34f7647c842Fa4, 140000000, year.add(6 * month), false);

         
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, 0  , false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, 3 * month, false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, 6 * month, false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, 9 * month, false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, year, false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 150000000, year.add(3 * month), false);
        setInitialDistribution(0xbca236d9F3f4c247fAC1854ad92EB3cE25847F2e, 100000000, year.add(6 * month), false);

         
        setInitialDistribution(0xafa64cCa337eFEE0AD827F6C2684e69275226e90, 22500000, 0  , false);
        setInitialDistribution(0xafa64cCa337eFEE0AD827F6C2684e69275226e90, 90000000, month, true);
         
        setInitialDistribution(0x4a9fA34da6d2378c8f3B9F6b83532B169beaEDFc, 1500000, 0  , false);
        setInitialDistribution(0x4a9fA34da6d2378c8f3B9F6b83532B169beaEDFc, 6000000, month, true);
         
        setInitialDistribution(0x149D6b149cCF5A93a19b62f6c8426dc104522A48, 900000, 0  , false);
        setInitialDistribution(0x149D6b149cCF5A93a19b62f6c8426dc104522A48, 3600000, month, true);
         
        setInitialDistribution(0x004988aCd23524303B999A6074424ADf3f929eA1, 7500000, 0  , false);
        setInitialDistribution(0x004988aCd23524303B999A6074424ADf3f929eA1, 30000000, month, true);
         
        setInitialDistribution(0xe3b7C5A000FCd6EfEa699c67F59419c7826f4A33, 70500000, 0  , false);
        setInitialDistribution(0xe3b7C5A000FCd6EfEa699c67F59419c7826f4A33, 282000000, month, true);
         
        setInitialDistribution(0x9A17D8ad0906D1dfcd79337512eF7Dc20caB5790, 50000000, 0  , false);
        setInitialDistribution(0x9A17D8ad0906D1dfcd79337512eF7Dc20caB5790, 200000000, month, true);
         
        setInitialDistribution(0x1299b87288e3A997165C738d898ebc6572Fb3905, 30000000, 0  , false);
        setInitialDistribution(0x1299b87288e3A997165C738d898ebc6572Fb3905, 120000000, month, true);
         
        setInitialDistribution(0xeF26a8cdD11127E5E6E2c324EC001159651aBa6e, 15000000, 0  , false);
        setInitialDistribution(0xeF26a8cdD11127E5E6E2c324EC001159651aBa6e, 60000000, month, true);
         
        setInitialDistribution(0xE6A21B21355D43754EB6166b266C033f4bc172A4, 102100000, 0  , false);
        setInitialDistribution(0xE6A21B21355D43754EB6166b266C033f4bc172A4, 408400000, month, true);
       
         
        setInitialDistribution(0xa8Ff08339F023Ea7B66F32586882c31DB4f35576, 25000000, 0  , false);

    }

    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused  {
        erc20 = ERC20(_tokenAddress);
    }
    
    function safeGuardAllTokens(address _address) external onlyOwner whenPaused  {  
        require(erc20.transfer(_address, erc20.balanceOf(address(this))));
    }

    function setTGEDate(uint256 _time) external onlyOwner whenNotPaused  {
        TGEDate = _time;
    }

     

    function triggerTokenSend() external whenNotPaused  {
         
        require(TGEDate != 0, "TGE date not set yet");
         
        require(block.timestamp > TGEDate, "TGE still hasn´t started");
         
        require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
        lastDateDistribution = block.timestamp;
         
        for(uint i = 0; i < tokenOwners.length; i++) {
             
            DistributionStep[] memory d = distributions[tokenOwners[i]];
             
            for(uint j = 0; j < d.length; j++){
                if( (block.timestamp.sub(TGEDate) > d[j].unlockDay)  
                    && (d[j].currentAllocated > 0)  
                ){
                     
                    bool isDaily = d[j].isDaily;
                    uint256 sendingAmount;
                    if(!isDaily){
                         
                        sendingAmount = d[j].currentAllocated;
                    }else{
                         
                        if(daysPassed >= 365){
                             
                            sendingAmount = d[j].currentAllocated;
                        }else{
                            sendingAmount = d[j].amountAllocated.div(daysLockWhenDaily); 
                        }
                        daysPassed = daysPassed.add(1);
                    }

                    distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
                    distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
                    require(erc20.transfer(tokenOwners[i], sendingAmount));
                }
            }
        }   
    }

    function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays, bool _isDaily) internal onlyOwner whenNotPaused {
         
        bool isAddressPresent = false;

         
        for(uint i = 0; i < tokenOwners.length; i++) {
            if(tokenOwners[i] == _address){
                isAddressPresent = true;
            }
        }
         
        DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0, _isDaily);
         
        distributions[_address].push(distributionStep);

         
        if(!isAddressPresent){
            tokenOwners.push(_address);
        }

    }
}
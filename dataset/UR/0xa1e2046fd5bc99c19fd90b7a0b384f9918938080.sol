 

pragma solidity ^0.4.22;

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
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = 0x0;
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


contract Whitelist is Ownable {
    uint256 public count;
    using SafeMath for uint256;

     
    mapping (address => bool) public whitelist;
    mapping (uint256 => address) public indexlist;
    mapping (address => uint256) public reverseWhitelist;


    constructor() public {
        count = 0;
    }
    
    function AddWhitelist(address account) public onlyOwner returns(bool) {
        require(account != address(0));
        whitelist[account] = true;
        if( reverseWhitelist[account] == 0 ) {
            count = count.add(1);
            indexlist[count] = account;
            reverseWhitelist[account] = count;
        }
        return true;
    }

    function GetLengthofList() public view returns(uint256) {
        return count;
    }

    function RemoveWhitelist(address account) public onlyOwner {
        require( reverseWhitelist[account] != 0 );
        whitelist[account] = false;
    }

    function GetWhitelist(uint256 index) public view returns(address) {
        return indexlist[index];        
    }
    
    function IsWhite(address account) public view returns(bool) {
        return whitelist[account];
    }
}


contract Formysale is Ownable, Pausable, Whitelist {    
    uint256 public weiRaised;          
    uint256 public personalMincap;     
    uint256 public personalMaxcap;     
    uint256 public startTime;          
    uint256 public endTime;            
    uint256 public exchangeRate;       
    uint256 public remainToken;        
    bool    public isFinalized;        

    uint256 public mtStartTime;        
    uint256 public mtEndTime;          


    mapping (address => uint256) public beneficiaryFunded;  
    mapping (address => uint256) public beneficiaryBought;  

    event Buy(address indexed beneficiary, uint256 payedEther, uint256 tokenAmount);

    constructor(uint256 _rate) public { 
        startTime = 1532919600;            
        endTime = 1534647600;              
        remainToken = 6500000000 * 10 ** 18;  

        exchangeRate = _rate;
        personalMincap = (1 ether);
        personalMaxcap = (1000 ether);
        isFinalized = false;
        weiRaised = 0x00;
        mtStartTime = 28800;   
        mtEndTime = 32400;     
    }    

    function buyPresale() public payable whenNotPaused {
        address beneficiary = msg.sender;
        uint256 toFund = msg.value;      

         
        uint256 tokenAmount = SafeMath.mul(toFund,exchangeRate);
         
        require(!isFinalized);
        require(validPurchase());        
        require(whitelist[beneficiary]); 
        require(remainToken >= tokenAmount); 
                

        weiRaised = SafeMath.add(weiRaised, toFund);             
        remainToken = SafeMath.sub(remainToken, tokenAmount);    
        beneficiaryFunded[beneficiary] = SafeMath.add(beneficiaryFunded[msg.sender], toFund);
        beneficiaryBought[beneficiary] = SafeMath.add(beneficiaryBought[msg.sender], tokenAmount);

        emit Buy(beneficiary, toFund, tokenAmount);
        
    }

    function validPurchase() internal view returns (bool) {
         
        bool validValue = msg.value >= personalMincap && beneficiaryFunded[msg.sender].add(msg.value) <= personalMaxcap;

         
        bool validTime = now >= startTime && now <= endTime && !checkMaintenanceTime();

        return validValue && validTime;
    }

    function checkMaintenanceTime() public view returns (bool){
        uint256 datetime = now % (60 * 60 * 24);
        return (datetime >= mtStartTime && datetime < mtEndTime);
    }

    function getNowTime() public view returns(uint256) {
        return now;
    }

     
    function changeStartTime( uint64 newStartTime ) public onlyOwner {
        startTime = newStartTime;
    }

    function changeEndTime( uint64 newEndTime ) public onlyOwner {
        endTime = newEndTime;
    }

    function changePersonalMincap( uint256 newpersonalMincap ) public onlyOwner {
        personalMincap = newpersonalMincap * (1 ether);
    }

    function changePersonalMaxcap( uint256 newpersonalMaxcap ) public onlyOwner {
        personalMaxcap = newpersonalMaxcap * (1 ether);
    }

    function FinishTokenSale() public onlyOwner {
        require(now > endTime || remainToken == 0);
        isFinalized = true;        
        owner.transfer(weiRaised);  
    }

    function changeRate(uint256 _newRate) public onlyOwner {
        require(checkMaintenanceTime());
        exchangeRate = _newRate; 
    }

    function changeMaintenanceTime(uint256 _startTime, uint256 _endTime) public onlyOwner{
        mtStartTime = _startTime;
        mtEndTime = _endTime;
    }

     
    function () public payable {
        buyPresale();
    }

}
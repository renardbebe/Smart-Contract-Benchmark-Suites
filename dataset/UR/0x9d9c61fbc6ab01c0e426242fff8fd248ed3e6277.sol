 

pragma solidity ^0.4.21;


contract Owner {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owner(address _owner) public {
        owner = _owner;
    }

    function changeOwner(address _newOwnerAddr) public onlyOwner {
        require(_newOwnerAddr != address(0));
        owner = _newOwnerAddr;
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


contract KIMEX is Owner {
    using SafeMath for uint256;

    string public constant name = "KIMEX";
    string public constant symbol = "KMX";
    uint public constant decimals = 18;
    uint256 constant public totalSupply = 250000000 * 10 ** 18;  
  
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    address public adminAddress;
    address public walletAddress;
    address public founderAddress;
    address public teamAddress;

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public totalInvestedAmountOf;

    uint constant lockPeriod1 = 1 years;  
   
    uint constant NOT_SALE = 0;  
    uint constant IN_SALE = 1;   
    uint constant END_SALE = 2;  

    uint256 public constant salesAllocation = 150000000 * 10 ** 18;  
    uint256 public constant reservedAllocation = 22500000 * 10 ** 18;  
    uint256 public constant founderAllocation = 50000000 * 10 ** 18;  
    uint256 public constant teamAllocation = 22500000 * 10 ** 18;  
    uint256 public constant minInvestedCap = 5000 * 10 ** 18;  
    uint256 public constant minInvestedAmount = 0.1 * 10 ** 18;  
    
    uint saleState;
    uint256 totalInvestedAmount;
    uint public icoStartTime;
    uint public icoEndTime;
    bool public inActive;
    bool public isSelling;
    bool public isTransferable;
    uint public founderAllocatedTime = 1;
    uint public teamAllocatedTime = 1;
    uint256 public icoStandardPrice;
 
    uint256 public totalRemainingTokensForSales;  
    uint256 public totalReservedTokenAllocation;  
    uint256 public totalLoadedRefund;  
    uint256 public totalRefundedAmount;  

    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);  

    event ModifyWhiteList(address investorAddress, bool isWhiteListed);   
    event StartICO(uint state);  
    event EndICO(uint state);  
    
    event SetICOPrice(uint256 price);  
    
    
    event IssueTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint state);  
    event RevokeTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint256 txFee);  
    event AllocateTokensForFounder(address founderAddress, uint256 founderAllocatedTime, uint256 tokenAmount);  
    event AllocateTokensForTeam(address teamAddress, uint256 teamAllocatedTime, uint256 tokenAmount);  
    event AllocateReservedTokens(address reservedAddress, uint256 tokenAmount);  
    

    modifier isActive() {
        require(inActive == false);
        _;
    }

    modifier isInSale() {
        require(isSelling == true);
        _;
    }

    modifier transferable() {
        require(isTransferable == true);
        _;
    }

    modifier onlyOwnerOrAdminOrPortal() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    function KIMEX(address _walletAddr, address _adminAddr) public Owner(msg.sender) {
        require(_walletAddr != address(0));
        require(_adminAddr != address(0));
		
        walletAddress = _walletAddr;
        adminAddress = _adminAddr;
        inActive = true;
        totalInvestedAmount = 0;
        totalRemainingTokensForSales = salesAllocation;
        totalReservedTokenAllocation = reservedAllocation;
    }

     
    function () external payable isActive isInSale {
        uint state = getCurrentState();
        require(state < END_SALE);
        require(msg.value >= minInvestedAmount);
       
        if (state <= IN_SALE) {
            return issueTokensForICO(state);
        }
        revert();
    }

     
    function loadFund() external payable {
        require(msg.value > 0);
		
        totalLoadedRefund = totalLoadedRefund.add(msg.value);
    }

     
    function transfer(address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) external transferable returns (bool) {
        require(_spender != address(0));
        require(_value > 0);
		
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function modifyWhiteList(address[] _investorAddrs, bool _isWhiteListed) external isActive onlyOwnerOrAdminOrPortal returns(bool) {
        for (uint256 i = 0; i < _investorAddrs.length; i++) {
            whiteList[_investorAddrs[i]] = _isWhiteListed;
            emit ModifyWhiteList(_investorAddrs[i], _isWhiteListed);
        }
        return true;
    }

     
    function startICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(icoStandardPrice > 0);
        saleState = IN_SALE;
        icoStartTime = now;
        isSelling = true;
        emit StartICO(saleState);
        return true;
    }

     
    function endICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(icoEndTime == 0);
		
        saleState = END_SALE;
        isSelling = false;
        icoEndTime = now;
        emit EndICO(saleState);
        return true;
    }
    
     
    function setICOPrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
    		
        icoStandardPrice = _tokenPerEther;
        emit SetICOPrice(icoStandardPrice);
        return true;
    }
     
    function activate() external onlyOwner {
        inActive = false;
    }

     
    function deActivate() external onlyOwner {
        inActive = true;
    }

     
    function enableTokenTransfer() external isActive onlyOwner {
        isTransferable = true;
    }

     
    function changeWallet(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(walletAddress != _newAddress);
        walletAddress = _newAddress;
    }

     
    function changeAdminAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(adminAddress != _newAddress);
        adminAddress = _newAddress;
    }
  
     
    function changeFounderAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(founderAddress != _newAddress);
        founderAddress = _newAddress;
    }

     
    function changeTeamAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(teamAddress != _newAddress);
        teamAddress = _newAddress;
    }

     
    function allocateTokensForFounder() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(founderAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            amount = founderAllocation;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        revert();
    }

     
    function allocateTokensForTeam() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(teamAddress != address(0));
        uint256 amount;
        if (teamAllocatedTime == 1) {
            amount = teamAllocation * 40/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 2;
            return;
        }
        if (teamAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod1);
            amount = teamAllocation * 60/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 3;
            return;
        }
        revert();
    }

     
    function allocateReservedTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalReservedTokenAllocation = totalReservedTokenAllocation.sub(_amount);
        emit AllocateReservedTokens(_addr, _amount);
    }

     
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function getCurrentState() public view returns(uint256) {
        return saleState;
    }

     
    function isSoftCapReached() public view returns (bool) {
        return totalInvestedAmount >= minInvestedCap;
    }
    
      
    function issueTokensForICO(uint _state) private {
        uint256 price = icoStandardPrice;
        issueTokens(price, _state);
    }

     
    function issueTokens(uint256 _price, uint _state) private {
        require(walletAddress != address(0));
		
        uint tokenAmount = msg.value.mul(_price).mul(10**18).div(1 ether);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        totalInvestedAmountOf[msg.sender] = totalInvestedAmountOf[msg.sender].add(msg.value);
        totalRemainingTokensForSales = totalRemainingTokensForSales.sub(tokenAmount);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        walletAddress.transfer(msg.value);
        emit IssueTokens(msg.sender, msg.value, tokenAmount, _state);
    }
}
 

pragma solidity 0.5.9;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract HotelierCoin {
    
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private _owner;
    uint8 private _decimals;
    bool private _isReserveEnabled;
    
         
    
    uint8 private _code_for_department_of_team = 100;  
    uint8 private _code_for_department_of_foundation_community_building = 103;  
    uint8 private _code_for_department_of_advisor = 104;  
    uint8 private _code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop = 101;  
    uint8 private _code_for_reserve_account = 102;  
    
    uint8 private _code_for_reserve_private_sales = 105;  
    
     
     
    
    
      
    mapping (address => uint256) private _balances;
    mapping(uint8 => address) private _departmentInfo;
    mapping(address => uint8) private _departmentCodeInfo;
    mapping (address => mapping (address => uint256)) private _allowances;
    
     
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event MintOccured(uint256 totalCoins, address source);
    
    event ChangeOfDepartment(address oldAddy, address newlyAssignedAddy);
    
    event ReserveEnabled();
    
     
        
    constructor () public {
        _name = "HotelierCoin";
        _symbol = "HTLC";
        _decimals = 8;
        _totalSupply = 15000000000000000;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        _isReserveEnabled = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner,"ONLY AN OWNER CAN CALL THIS FUNCTION");
        _;
    }
    
     
     
    function contractCreator() public view returns(address){
        return _owner;
    }

     
     
    function name() public view returns (string memory) {
        return _name;
    }

     
     
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
     
     
     function decimals() public view returns(uint8 decimalCount){
         return _decimals;
     }
    
     
     
    function totalSupply() external view returns(uint256){
        return _totalSupply;
    }
    
     
     
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
    
     
     
     function departmentCodeInfo(address departmentAddress) public view returns(uint8){
         require(_departmentCodeInfo[departmentAddress] != 0, "ADDRESS IS NOT IN USE IN ANY DEPARTMENT");
         return _departmentCodeInfo[departmentAddress];
     }
    
    
     
     
    function departmentInfo(uint8 departmentCode) public view returns(address){
         require(_departmentInfo[departmentCode] != address(0), "NO ADDRESS EXISTS");
        return _departmentInfo[departmentCode];
    }    
    
     
     
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function changeDepartmentAddress( address _addr, uint8 _departmentCode ) public onlyOwner returns (bool){
        
        require(_departmentInfo[_departmentCode] != address(0), "NO ZERO ADDRESS CAN BE MADE DEPARTMENT ADDRESS");
        
        for(uint8 i=100;i<106;i++){
            require(_departmentInfo[i] != _addr, "NO TWO DEPARTMENTS CAN HAVE THE SAME ADDRESS");
        }
        
        uint256 _balanceToApprove = _balances[_departmentInfo[_departmentCode]];
        _balances[_departmentInfo[_departmentCode]] = _balances[_departmentInfo[_departmentCode]].sub(_balanceToApprove);
        _balances[_addr] = _balances[_addr].add(_balanceToApprove);
        
        _allowances[_addr][msg.sender] = _balances[_addr];
        
        emit ChangeOfDepartment(_departmentInfo[_departmentCode], _addr);
        emit Approval(_addr,msg.sender,_balanceToApprove);
        emit Transfer(_departmentInfo[_departmentCode], _addr, _balances[_departmentInfo[_departmentCode]]);
        
        _departmentInfo[_departmentCode] = _addr;
        _departmentCodeInfo[_addr] = _departmentCode;
        return true;
        
    }
    
    function mint() public onlyOwner returns(bool){
        
        require(_balances[_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop]] < 1000,"CONDITIONS NOT MET FOR MINTING");
        
        address team = _departmentInfo[_code_for_department_of_team];
        uint256 teamShare = 150000000000000;
        
        address communityBuilding = _departmentInfo[_code_for_department_of_foundation_community_building];
        uint256 communityBuildingShare = 350000000000000;
        
        address reserve = _departmentInfo[_code_for_reserve_account];
        require(_balances[reserve] < 500000000000000, "MINTING NOT POSSIBLE");
        uint256 reserveShare = 4500000000000000;
        
        
        require(team != address(0), "FORBIDDEN!:: MINT");
        require(communityBuilding != address(0), "FORBIDDEN!:: MINT");
        require(reserve != address(0), "FORBIDDEN!:: MINT");
        
        require(teamShare + communityBuildingShare + reserveShare == 5000000000000000, "MINTING VALUE ERROR!" );

        _mint(team,communityBuilding, reserve, teamShare, communityBuildingShare, reserveShare);
        return true;
        
    }

    function transfer(address to, uint256 value) external returns (bool) {
        
        _transfer(msg.sender, to, value);
        return true;
        
    }
    
     
    
    function setReserve(address reserve) external onlyOwner returns(bool){
        require(_departmentInfo[_code_for_reserve_account] == address(0));
        require(_departmentInfo[_code_for_reserve_private_sales] != reserve, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != reserve, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_advisor] != reserve, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_foundation_community_building] != reserve, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_team] != reserve, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(reserve != address(0));
        _departmentInfo[_code_for_reserve_account] =reserve;
        _departmentCodeInfo[reserve] = _code_for_reserve_account;
        _transfer(msg.sender, reserve, 5000000000000000);
        _approve(reserve,_owner, 5000000000000000);
        return true;
        
    }
    
     
     
    function setTeam(address team) external onlyOwner returns(bool){
        require(_departmentInfo[_code_for_department_of_team] == address(0));
        require(_departmentInfo[_code_for_reserve_private_sales] != team, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != team, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_advisor] != team, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_foundation_community_building] != team, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_reserve_account] != team, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(team != address(0));
        _departmentInfo[_code_for_department_of_team] =team;
        _departmentCodeInfo[team] = _code_for_department_of_team;
        _transfer(msg.sender, team, 2300000000000000);
        _approve(team,_owner, 2300000000000000);
        return true;
        
    }
    
     
     
    function setFoundationCommunityBuilding(address community) external onlyOwner returns(bool){
        require(_departmentInfo[_code_for_department_of_foundation_community_building] == address(0));
        require(_departmentInfo[_code_for_reserve_private_sales] != community, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != community, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_advisor] != community, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_team] != community, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_reserve_account] != community, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(community != address(0));
        _departmentInfo[_code_for_department_of_foundation_community_building] =community;
        _departmentCodeInfo[community] = _code_for_department_of_foundation_community_building;
        _transfer(msg.sender, community, 300000000000000);
        _approve(community,_owner, 300000000000000);
        return true;
        
    }
    
     
    
    function setAdvisor(address advisor) external onlyOwner returns(bool){
        require(_departmentInfo[_code_for_department_of_advisor] == address(0));
        require(_departmentInfo[_code_for_reserve_private_sales] != advisor, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != advisor, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_foundation_community_building] != advisor, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_team] != advisor, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_reserve_account] != advisor, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(advisor != address(0));
        _departmentInfo[_code_for_department_of_advisor] =advisor;
        _departmentCodeInfo[advisor] = _code_for_department_of_advisor;
        _transfer(msg.sender, advisor, 400000000000000);
        _approve(advisor,_owner, 400000000000000);
        return true;
        
    }
    
     
    
    function setCashbackSalesIeoRewardsAirdrop(address cashback) external onlyOwner returns(bool){
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] == address(0));
        require(_departmentInfo[_code_for_reserve_private_sales] != cashback, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_advisor] != cashback, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_foundation_community_building] != cashback, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_team] != cashback, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_reserve_account] != cashback, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(cashback != address(0));
        _departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] =cashback;
        _departmentCodeInfo[cashback] = _code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop;
        _transfer(msg.sender, cashback, 7000000000000000);
        _approve(cashback,_owner, 7000000000000000);
        return true;
        
    }
    
     
     
    function setPrivateSalesFromReserve(address privateSales) external onlyOwner returns(bool){
        
        require(_departmentInfo[_code_for_reserve_private_sales] == address(0));
        require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != privateSales, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_advisor] != privateSales, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_foundation_community_building] != privateSales, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_department_of_team] != privateSales, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(_departmentInfo[_code_for_reserve_account] != privateSales, "ADDRESS ALREADY EXISTS FOR OTHER DEPARTMENT");
        require(privateSales != address(0));
        require(_allowances[_departmentInfo[_code_for_reserve_account]][msg.sender]  > 0, "RESERVE ADDRESS MUST EXIST AND SET");
        _departmentInfo[_code_for_reserve_private_sales] = privateSales;
        _departmentCodeInfo[privateSales] = _code_for_reserve_private_sales;
        _transfer(_departmentInfo[_code_for_reserve_account], privateSales, 250000000000000);
        _approve(privateSales,_owner, 250000000000000);
        return true;
        
    }
    

    function transferFrom(address from, address to ,uint256 value) external returns (bool) {
        
        require(_allowances[from][msg.sender] > value , "NOT ENOUGH ALLOWANCE VALUE TO SPEND");
        _transfer(from, to, value);
        _approve(from, msg.sender,_allowances[from][msg.sender].sub(value));
        return true;
        
    }

    function _transfer(address from, address to, uint256 _value) internal {
        
        require(from != address(0));
        require(to != address(0));
        if(_departmentInfo[_code_for_reserve_account] == from){
            require(_isReserveEnabled == true, "RESERVE CANT BE USED");
        }
        
            _balances[from] = _balances[from].sub(_value);
            _balances[to] = _balances[to].add(_value);
            
     
            emit Transfer(from, to, _value);
        
        
    }
    
     function enableReserveTransfers() external onlyOwner returns(bool){
         require(_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop] != address(0));
         require(_balances[_departmentInfo[_code_for_department_of_cashback_sales_ieo_p2p_rewards_airdrop]] <1000);
            _isReserveEnabled = true;
            emit ReserveEnabled();
    }

    function _mint(address team, address communityBuilding, address reserve, uint256 teamShare, uint256 communityBuildingShare, uint256 reserveShare) internal {
        uint256 totalMintedCoins = teamShare + communityBuildingShare + reserveShare;
        _totalSupply = _totalSupply.add(totalMintedCoins);
        
        _balances[team] = _balances[team].add(teamShare);
        _balances[communityBuilding] = _balances[communityBuilding].add(communityBuildingShare);
        _balances[reserve] = _balances[reserve].add(reserveShare);
        
        _allowances[team][_owner] = _allowances[team][_owner].add(teamShare);
        _allowances[communityBuilding][_owner] = _allowances[communityBuilding][_owner].add(communityBuildingShare);
        _allowances[reserve][_owner] = _allowances[reserve][_owner].add(reserveShare);
        
        emit Approval(team,_owner,teamShare);
        emit Approval(communityBuilding,_owner,communityBuildingShare);
        emit Approval(reserve,_owner,reserveShare);
        
        emit Transfer(address(0), team, teamShare);
        emit Transfer(address(0), communityBuilding, communityBuildingShare);
        emit Transfer(address(0), reserve, reserveShare);
        
        emit MintOccured(totalMintedCoins, msg.sender);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}
 

pragma solidity 0.4.25;

 

contract Wallie
{
     
	mapping (address => Investor) public investors;

	 
	event NewInvestor(address _addr, uint256 _amount);

	 
	event CashbackBonus(address _addr, uint256 _amount, uint256 _revenue);

	 
	event RefererBonus(address _from, address _to, uint256 _amount, uint256 _revenue, uint256 _level);

	 
	event NewInvestment(address _addr, uint256 _amount);

	 
	event NewWithdraw(address _addr, uint256 _amount);

	 
	event ChangeBalance(uint256 _balance);

	struct Investor {
		 
		address addr;
		 
		address referer;
		 
		uint256 investment;
		 
		uint256 investment_time;
		 
		uint256 investment_first_time_in_day;
		 
		uint256 investments_daily;
		 
		uint256 investment_profit;
		 
		uint256 referals_profit;
		 
		uint256 cashback_profit;
		 
		uint256 investment_profit_balance;
		 
		uint256 referals_profit_balance;
		 
		uint256 cashback_profit_balance;
	}

	 
	uint256 private constant dividends_perc_before_2000eth = 11;         
	 
	uint256 private constant dividends_perc_after_2000eth = 12;          
	 
	uint256 public constant ref_bonus_level_1 = 5;                       
	 
	uint256 public constant ref_bonus_level_2 = 3;                       
	 
	uint256 public constant ref_bonus_level_3 = 1;                       
	 
	uint256 public constant cashback_bonus = 3;                          
	 
	uint256 public constant min_invesment = 10 finney;                   
	 
	uint256 public constant advertising_fees = 15;                       
	 
	uint256 public constant contract_daily_limit = 100 ether;
	 
	bool public block_investments = true;
	 
	bool public compensation = true;

	 
	address first_project_addr = 0xC0B52b76055C392D67392622AE7737cdb6D42133;

	 
	uint256 public start_time;
	 
	uint256 current_day;
	 
	uint256 start_day;
	 
	uint256 daily_invest_to_contract;
	 
	address private adm_addr;
	 
	uint256 public start_block;
	 
	bool public is_started = false;
	
	 
	 
	uint256 private all_invest_users_count = 0;
	 
	uint256 private all_invest = 0;
	 
	uint256 private all_payments = 0;
	 
	address private last_invest_addr = 0;
	 
	uint256 private last_invest_amount = 0;

	using SafeMath for uint;
    using ToAddress for *;
    using Zero for *;

constructor() public {
		adm_addr = msg.sender;
		current_day = 0;
		daily_invest_to_contract = 0;
	}

	 
	function getTime() public view returns (uint256) {
		return (now);
	}

	 
	function createInvestor(address addr,address referer) private {
		investors[addr].addr = addr;
		if (investors[addr].referer.isZero()) {
			investors[addr].referer = referer;
		}
		all_invest_users_count++;
		emit NewInvestor(addr, msg.value);
	}

	 
	function checkInvestor(address addr) public view returns (bool) {
		if (investors[addr].addr.isZero()) {
			return false;
		}
		else {
			return true;
		}
	}

	 
	function setRefererBonus(address addr, uint256 amount, uint256 level_percent, uint256 level_num) private {
		if (addr.notZero()) {
			uint256 revenue = amount.mul(level_percent).div(100);

			if (!checkInvestor(addr)) {
				createInvestor(addr, address(0));
			}

			investors[addr].referals_profit = investors[addr].referals_profit.add(revenue);
			investors[addr].referals_profit_balance = investors[addr].referals_profit_balance.add(revenue);
			emit RefererBonus(msg.sender, addr, amount, revenue, level_num);
		}
	}

	 
	function setAllRefererBonus(address addr, uint256 amount) private {

		address ref_addr_level_1 = investors[addr].referer;
		address ref_addr_level_2 = investors[ref_addr_level_1].referer;
		address ref_addr_level_3 = investors[ref_addr_level_2].referer;

		setRefererBonus (ref_addr_level_1, amount, ref_bonus_level_1, 1);
		setRefererBonus (ref_addr_level_2, amount, ref_bonus_level_2, 2);
		setRefererBonus (ref_addr_level_3, amount, ref_bonus_level_3, 3);
	}

	 
	function calcDivedents (address addr) public view returns (uint256) {
		uint256 current_perc = 0;
		if (address(this).balance < 2000 ether) {
			current_perc = dividends_perc_before_2000eth;
		}
		else {
			current_perc = dividends_perc_after_2000eth;
		}

		return investors[addr].investment.mul(current_perc).div(1000).mul(now.sub(investors[addr].investment_time)).div(1 days);
	}

	 
	function setDivedents(address addr) private returns (uint256) {
		investors[addr].investment_profit_balance = investors[addr].investment_profit_balance.add(calcDivedents(addr));
	}

	 
	function setAmount(address addr, uint256 amount) private {
		investors[addr].investment = investors[addr].investment.add(amount);
		investors[addr].investment_time = now;
		all_invest = all_invest.add(amount);
		last_invest_addr = addr;
		last_invest_amount = amount;
		emit NewInvestment(addr,amount);
	}

	 
	function setCashBackBonus(address addr, uint256 amount) private {
		if (investors[addr].referer.notZero() && investors[addr].investment == 0) {
			investors[addr].cashback_profit_balance = amount.mul(cashback_bonus).div(100);
			investors[addr].cashback_profit = investors[addr].cashback_profit.add(investors[addr].cashback_profit_balance);
			emit CashbackBonus(addr, amount, investors[addr].cashback_profit_balance);
		}
	}

	 
	function withdraw_revenue(address addr) private {
		uint256 withdraw_amount = calcDivedents(addr);
		
		if (check_x2_profit(addr,withdraw_amount) == true) {
		   withdraw_amount = 0; 
		}
		
		if (withdraw_amount > 0) {
		   investors[addr].investment_profit = investors[addr].investment_profit.add(withdraw_amount); 
		}
		
		withdraw_amount = withdraw_amount.add(investors[addr].investment_profit_balance).add(investors[addr].referals_profit_balance).add(investors[addr].cashback_profit_balance);
		

		if (withdraw_amount > 0) {
			clear_balance(addr);
			all_payments = all_payments.add(withdraw_amount);
			emit NewWithdraw(addr, withdraw_amount);
			emit ChangeBalance(address(this).balance.sub(withdraw_amount));
			addr.transfer(withdraw_amount);
		}
	}

	 
	function clear_balance(address addr) private {
		investors[addr].investment_profit_balance = 0;
		investors[addr].referals_profit_balance = 0;
		investors[addr].cashback_profit_balance = 0;
		investors[addr].investment_time = now;
	}

	 
	function check_x2_profit(address addr, uint256 dividends) private returns(bool) {
		if (investors[addr].investment_profit.add(dividends) > investors[addr].investment.mul(2)) {
		    investors[addr].investment_profit_balance = investors[addr].investment.mul(2).sub(investors[addr].investment_profit);
			investors[addr].investment = 0;
			investors[addr].investment_profit = 0;
			investors[addr].investment_first_time_in_day = 0;
			investors[addr].investment_time = 0;
			return true;
		}
		else {
		    return false;
		}
	}

	function() public payable
	isStarted
	rerfererVerification
	isBlockInvestments
	minInvest
	allowInvestFirstThreeDays
	setDailyInvestContract
	setDailyInvest
	maxInvestPerUser
	maxDailyInvestPerContract
	setAdvertisingComiss {

		if (msg.value == 0) {
			 
			withdraw_revenue(msg.sender);
		}
		else
		{
			 
			address ref_addr = msg.data.toAddr();

			 
			if (!checkInvestor(msg.sender)) {
				 
				createInvestor(msg.sender,ref_addr);
			}

			 
			setDivedents(msg.sender);

			 
			setCashBackBonus(msg.sender, msg.value);

			 
			setAmount(msg.sender, msg.value);

			 
			setAllRefererBonus(msg.sender, msg.value);
		}
	}

	 
	function today() public view returns (uint256) {
		return now.div(1 days);
	}

	 
	function BlockInvestments() public onlyOwner {
		block_investments = true;
	}

	 
	function AllowInvestments() public onlyOwner {
		block_investments = false;
	}
	
	 
	function DisableCompensation() public onlyOwner {
		compensation = false;
	}

	 
	function StartProject() public onlyOwner {
		require(is_started == false, "Project is started");
		block_investments = false;
		start_block = block.number;
		start_time = now;
		start_day = today();
		is_started = true;
	}
	
	 
	function getInvestorInfo(address addr) public view returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		Investor memory investor_info = investors[addr];
		return (investor_info.referer,
		investor_info.investment,
		investor_info.investment_time,
		investor_info.investment_first_time_in_day,
		investor_info.investments_daily,
		investor_info.investment_profit,
		investor_info.referals_profit,
		investor_info.cashback_profit,
		investor_info.investment_profit_balance,
		investor_info.referals_profit_balance,
		investor_info.cashback_profit_balance);
	}
	
	 
    function getWebStats() public view returns (uint256,uint256,uint256,uint256,address,uint256){
    return (all_invest_users_count,address(this).balance,all_invest,all_payments,last_invest_addr,last_invest_amount); 
    }

	 
	modifier isStarted() {
		require(is_started == true, "Project not started");
		_;
	}

	 
	modifier isBlockInvestments()
	{
		if (msg.value > 0) {
			require(block_investments == false, "investments is blocked");
		}
		_;
	}

	 
	modifier setDailyInvest() {
		if (now.sub(investors[msg.sender].investment_first_time_in_day) < 1 days) {
			investors[msg.sender].investments_daily = investors[msg.sender].investments_daily.add(msg.value);
		}
		else {
			investors[msg.sender].investments_daily = msg.value;
			investors[msg.sender].investment_first_time_in_day = now;
		}
		_;
	}

	 
	modifier maxInvestPerUser() {
		if (now.sub(start_time) <= 30 days) {
			require(investors[msg.sender].investments_daily <= 20 ether, "max payment must be <= 20 ETH");
		}
		else{
			require(investors[msg.sender].investments_daily <= 50 ether, "max payment must be <= 50 ETH");
		}
		_;
	}

	 
	modifier maxDailyInvestPerContract() {
		if (now.sub(start_time) <= 30 days) {
			require(daily_invest_to_contract <= contract_daily_limit, "all daily invest to contract must be <= 100 ETH");
		}
		_;
	}

	 
	modifier minInvest() {
		require(msg.value == 0 || msg.value >= min_invesment, "amount must be = 0 ETH or > 0.01 ETH");
		_;
	}

	 
	modifier setDailyInvestContract() {
		uint256 day = today();
		if (current_day == day) {
			daily_invest_to_contract = daily_invest_to_contract.add(msg.value);
		}
		else {
			daily_invest_to_contract = msg.value;
			current_day = day;
		}
		_;
	}

	 
	modifier allowInvestFirstThreeDays() {
		if (now.sub(start_time) <= 3 days && compensation == true) {
			uint256 invested = WallieFirstProject(first_project_addr).invested(msg.sender);

			require(invested > 0, "invested first contract must be > 0");

			uint256 payments = WallieFirstProject(first_project_addr).payments(msg.sender);

			uint256 payments_perc = payments.mul(100).div(invested);

			require(payments_perc <= 30, "payments first contract must be <= 30%");
		}
		_;
	}

	 
	modifier rerfererVerification() {
		address ref_addr = msg.data.toAddr();
		if (ref_addr.notZero()) {
			require(msg.sender != ref_addr, "referer must be != msg.sender");
			require(investors[ref_addr].referer != msg.sender, "referer must be != msg.sender");
		}
		_;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == adm_addr,"onlyOwner!");
		_;
	}

	 
	modifier setAdvertisingComiss() {
		if (msg.sender != adm_addr && msg.value > 0) {
			investors[adm_addr].referals_profit_balance = investors[adm_addr].referals_profit_balance.add(msg.value.mul(advertising_fees).div(100));
		}
		_;
	}

}

 
contract WallieFirstProject {

	mapping (address => uint256) public invested;

	mapping (address => uint256) public payments;
}

library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0);  
		uint256 c = a / b;
		 

		return c;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	 
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

library ToAddress
{
	function toAddr(uint source) internal pure returns(address) {
		return address(source);
	}

	function toAddr(bytes source) internal pure returns(address addr) {
		assembly { addr := mload(add(source,0x14)) }
		return addr;
	}
}

library Zero
{
	function requireNotZero(uint a) internal pure {
		require(a != 0, "require not zero");
	}

	function requireNotZero(address addr) internal pure {
		require(addr != address(0), "require not zero address");
	}

	function notZero(address addr) internal pure returns(bool) {
		return !(addr == address(0));
	}

	function isZero(address addr) internal pure returns(bool) {
		return addr == address(0);
	}
}
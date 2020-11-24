 

pragma solidity ^0.4.16;

 
library SafeMath {
	function mul(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) pure internal returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) pure internal returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

 
contract Ownable {
	address public owner;


	 
	function Ownable() public {
		owner = msg.sender;
	}


	 
	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert();
		}
		_;
	}


	 
	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}

}

 
contract ERC20 {
	uint256 public tokenTotalSupply;

	function balanceOf(address who) public view returns(uint256);

	function allowance(address owner, address spender) public view returns(uint256);

	function transfer(address to, uint256 value) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function transferFrom(address from, address to, uint256 value) public returns (bool success);

	function approve(address spender, uint256 value) public returns (bool success);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() public view returns (uint256 availableSupply);
}

 
contract SaveToken is ERC20, Ownable {
	using SafeMath for uint;

	string public name = "SaveToken";
	string public symbol = "SAVE";
	uint public decimals = 18;

	mapping(address => uint256) affiliate;
	function getAffiliate(address who) public view returns(uint256) {
		return affiliate[who];
	}

    struct AffSender {
        bytes32 aff_code;
        uint256 amount;
    }
    uint public no_aff = 0;
	mapping(uint => AffSender) affiliate_senders;
	function getAffiliateSender(bytes32 who) public view returns(uint256) {
	    
	    for (uint i = 0; i < no_aff; i++) {
            if(affiliate_senders[i].aff_code == who)
            {
                return affiliate_senders[i].amount;
            }
        }
        
		return 1;
	}
	function getAffiliateSenderPosCode(uint pos) public view returns(bytes32) {
	    if(pos >= no_aff)
	    {
	        return 1;
	    }
	    return affiliate_senders[pos].aff_code;
	}
	function getAffiliateSenderPosAmount(uint pos) public view returns(uint256) {
	    if(pos >= no_aff)
	    {
	        return 2;
	    }
	    return affiliate_senders[pos].amount;
	}

	uint256 public tokenTotalSupply = 0;
	uint256 public trashedTokens = 0;
	uint256 public hardcap = 350 * 1000000 * (10 ** decimals);  

	uint public ethToToken = 6000;  
	uint public noContributors = 0;


	 
	uint public tokenBonusForFirst = 10;  
	uint256 public soldForFirst = 0;
	uint256 public maximumTokensForFirst = 55 * 1000000 * (10 ** decimals);  

	uint public tokenBonusForSecond = 5;  
	uint256 public soldForSecond = 0;
	uint256 public maximumTokensForSecond = 52.5 * 1000000 * (10 ** decimals);  

	uint public tokenBonusForThird = 4;  
	uint256 public soldForThird = 0;
	uint256 public maximumTokensForThird = 52 * 1000000 * (10 ** decimals);  

	uint public tokenBonusForForth = 3;  
	uint256 public soldForForth = 0;
	uint256 public maximumTokensForForth = 51.5 * 1000000 * (10 ** decimals);  

	uint public tokenBonusForFifth = 0;  
	uint256 public soldForFifth = 0;
	uint256 public maximumTokensForFifth = 50 * 1000000 * (10 ** decimals);  

	uint public presaleStart = 1519344000;  
	uint public presaleEnd = 1521849600;  
    uint public weekOneStart = 1524355200;  
    uint public weekTwoStart = 1525132800;  
    uint public weekThreeStart = 1525824000;  
    uint public weekFourStart = 1526601600;  
    uint public tokenSaleEnd = 1527292800;  
    
    uint public saleOn = 1;
    uint public disown = 0;

	 
	address public ownerVault;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	 
	modifier onlyPayloadSize(uint size) {
		if (msg.data.length < size + 4) {
			revert();
		}
		_;
	}

	 
	modifier isUnderHardCap() {
		require(tokenTotalSupply <= hardcap);
		_;
	}

	 
	function SaveToken() public {
		ownerVault = msg.sender;
	}

	 
	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);

		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
		uint256 _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);

		return true;
	}

	 
	function masterTransferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public onlyOwner returns (bool success) {
	    if(disown == 1) revert();
	    
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		Transfer(_from, _to, _value);

		return true;
	}

	function totalSupply() public view returns (uint256 availableSupply) {
		return tokenTotalSupply;
	}

	 
	function balanceOf(address _owner) public view returns(uint256 balance) {
		return balances[_owner];
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {

		 
		 
		 
		 
		if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
			revert();
		}

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);

		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	 
	function changeEthToTokenRation(uint8 _ratio) public onlyOwner {
		if (_ratio != 0) {
			ethToToken = _ratio;
		}
	}

	 
	function showEthBalance() view public returns(uint256 remaining) {
		return this.balance;
	}

	 
	function decreaseSupply(uint256 value, address from) public onlyOwner returns (bool) {
	    if(disown == 1) revert();
	    
		balances[from] = balances[from].sub(value);
		trashedTokens = trashedTokens.add(value);
		tokenTotalSupply = tokenTotalSupply.sub(value);
		Transfer(from, 0, value);
		return true;
	}

	 
	function BuyTokensWithAffiliate(address _affiliate) public isUnderHardCap payable
	{
		affiliate[_affiliate] += msg.value;
		if (_affiliate == msg.sender){  revert(); }
		BuyTokens();
	}

	 
	function mintTokens(address _address, uint256 amount) public onlyOwner isUnderHardCap
	{
	    if(disown == 1) revert();
	    
		if (amount + tokenTotalSupply > hardcap) revert();
		if (amount < 1) revert();

		 
		balances[_address] = balances[_address] + amount;

		 
		tokenTotalSupply = tokenTotalSupply.add(amount);
		Transfer(this, _address, amount);
		noContributors++;
	}

	 
	function changeOwnerVault(address new_vault) public onlyOwner
	{
	    ownerVault = new_vault;
    }
    
	 
	function changePeriod(uint period_no, uint new_value) public onlyOwner
	{
		if(period_no == 1)
		{
		    presaleStart = new_value;
		}
		else if(period_no == 2)
		{
		    presaleEnd = new_value;
		}
		else if(period_no == 3)
		{
		    weekOneStart = new_value;
		}
		else if(period_no == 4)
		{
		    weekTwoStart = new_value;
		}
		else if(period_no == 5)
		{
		    weekThreeStart = new_value;
		}
		else if(period_no == 6)
		{
		    weekFourStart = new_value;
		}
		else if(period_no == 7)
		{
		    tokenSaleEnd = new_value;
		}
	}

	 
	function changeSaleOn(uint new_value) public onlyOwner
	{
	    if(disown == 1) revert();
	    
		saleOn = new_value;
	}

	 
	function changeDisown(uint new_value) public onlyOwner
	{
	    if(new_value == 1)
	    {
	        disown = 1;
	    }
	}

	 
	function BuyTokens() public isUnderHardCap payable {
		uint256 tokens;
		uint256 bonus;

        if(saleOn == 0) revert();
        
		if (now < presaleStart) revert();

		 
		if (now >= presaleEnd && now <= weekOneStart) revert();

		 
		if (now >= tokenSaleEnd) revert();

		 
		if (now >= presaleStart && now <= presaleEnd)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForFirst).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForFirst = soldForFirst.add(tokens);
			if (soldForFirst > maximumTokensForFirst) revert();
		}

		 
		if (now >= weekOneStart && now <= weekTwoStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForSecond).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForSecond = soldForSecond.add(tokens);
			if (soldForSecond > maximumTokensForSecond.add(maximumTokensForFirst).sub(soldForFirst)) revert();
		}

		 
		if (now >= weekTwoStart && now <= weekThreeStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForThird).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForThird = soldForThird.add(tokens);
			if (soldForThird > maximumTokensForThird.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond)) revert();
		}

		 
		if (now >= weekThreeStart && now <= weekFourStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForForth).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForForth = soldForForth.add(tokens);
			if (soldForForth > maximumTokensForForth.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond).add(maximumTokensForThird).sub(soldForThird)) revert();
		}

		 
		if (now >= weekFourStart && now <= tokenSaleEnd)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForFifth).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForFifth = soldForFifth.add(tokens);
			if (soldForFifth > maximumTokensForFifth.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond).add(maximumTokensForThird).sub(soldForThird).add(maximumTokensForForth).sub(soldForForth)) revert();
		}

		if (tokens == 0)
		{
			revert();
		}

        if (tokens + tokenTotalSupply > hardcap) revert();
		
		 
		balances[msg.sender] = balances[msg.sender] + tokens;

		 
		tokenTotalSupply = tokenTotalSupply.add(tokens);
		Transfer(this, msg.sender, tokens);
		noContributors++;
	}

	 
	function withdrawEthereum(uint256 _amount) public onlyOwner {
		require(_amount <= this.balance);  

		if (!ownerVault.send(_amount)) {
			revert();
		}
		Transfer(this, ownerVault, _amount);
	}


	 
	 
	 
	 
	 

	function transferReservedTokens(uint256 _amount) public onlyOwner
	{
	    if(disown == 1) revert();
	    
		if (now <= tokenSaleEnd) revert();

		assert(_amount <= (hardcap - tokenTotalSupply) );

		balances[ownerVault] = balances[ownerVault] + _amount;
		tokenTotalSupply = tokenTotalSupply + _amount;
		Transfer(this, ownerVault, _amount);
	}

	function() external payable {
		BuyTokens();

	}
}
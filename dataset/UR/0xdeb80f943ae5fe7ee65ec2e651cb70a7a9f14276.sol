 

pragma solidity ^ 0.5.1;
contract PoWHr{
	 
	 
	uint256 constant scaleFactor = 0x10000000000000000;

	int constant crr_n = 1;
	int constant crr_d = 2;

	int constant public price_coeff = -0x1337FA66607BADA55;

	 
	string constant public name = "Bond";
	string constant public symbol = "BOND";
	uint8 constant public decimals = 12;

	 
	mapping(address => uint256) public hodlBonds;
	 
	mapping(address => uint256) public avgFactor_ethSpent;
	 
	mapping(address => uint256) public avgFactor_buyInTimeSum;
	 
	mapping(address => uint256) public resolveWeight;

	 
	 
	mapping(address => int256) public payouts;

	 
	uint256 public _totalSupply;

	 
	uint256 public dissolvingResolves;
	 
	uint256 public dissolved;

	 
	uint public contractBalance;

	 
	uint256 public buySum;
	uint256 public sellSum;

	 
	uint public avgFactor_releaseWeight;
	uint public avgFactor_releaseTimeSum;
	 
	uint public genesis;

	 
	 
	int256 totalPayouts;

	 
	 
	uint256 earningsPerResolve;

	 
	ResolveToken public resolveToken;

	constructor() public{
		genesis = now;
		resolveToken = new ResolveToken( address(this) );
	}

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
	function getResolveContract() public view returns(address){ return address(resolveToken); }
	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return hodlBonds[_owner];
	}

	function fluxFee(uint paidAmount) public view returns (uint fee) {
		if (dissolvingResolves == 0)
			return 0;
		
		uint totalResolveSupply = resolveToken.totalSupply() - dissolved;
		return paidAmount * dissolvingResolves / totalResolveSupply * sellSum / buySum;
	}

	 
	 
	event Reinvest( address indexed addr, uint256 reinvested, uint256 dissolved, uint256 bonds, uint256 resolveTax);
	function reinvestEarnings(uint amountFromEarnings) public returns(uint,uint){
		 
		uint totalEarnings = resolveEarnings(msg.sender);
		require(amountFromEarnings <= totalEarnings, "the amount exceeds total earnings");
		uint oldWeight = resolveWeight[msg.sender];
		resolveWeight[msg.sender] = oldWeight *  (totalEarnings - amountFromEarnings) / totalEarnings;
		uint weightDiff = oldWeight - resolveWeight[msg.sender];
		dissolved += weightDiff;
		dissolvingResolves -= weightDiff;

		 
		int resolvePayoutDiff  = (int256) (earningsPerResolve * weightDiff);

		payouts[msg.sender] += (int256) (amountFromEarnings * scaleFactor) - resolvePayoutDiff;

		totalPayouts += (int256) (amountFromEarnings * scaleFactor) - resolvePayoutDiff;

		 
		uint value_ = (uint) (amountFromEarnings);

		 
		if (value_ < 0.000001 ether)
			revert();

		 
		address sender = msg.sender;

		 
		uint fee = fluxFee(value_);

		 
		uint numEther = value_ - fee;
		buySum += numEther;

		 
		uint currentTime = NOW();
		avgFactor_ethSpent[msg.sender] += numEther;
		avgFactor_buyInTimeSum[msg.sender] += currentTime * scaleFactor * numEther;

		 
		uint createdBonds = calculateBondsFromReinvest(numEther, amountFromEarnings);

		 
		uint resolveFee;

		 
		if (_totalSupply > 0 && fee > 0) {
			resolveFee = fee * scaleFactor;

			 
			 
			uint rewardPerResolve = resolveFee / dissolvingResolves;

			 
			earningsPerResolve += rewardPerResolve;
		}

		 
		_totalSupply += createdBonds;

		 
		hodlBonds[sender] += createdBonds;

		emit Reinvest(msg.sender, value_, weightDiff, createdBonds, resolveFee);
		return (createdBonds, weightDiff);
	}

	 
	function sellAllBonds() public {
		sell( balanceOf(msg.sender) );
	}
	function sellBonds(uint amount) public returns(uint,uint){
		uint balance = balanceOf(msg.sender);
		require(balance >= amount, "Amount is more than balance");
		uint returned_eth;
		uint returned_resolves;
		(returned_eth, returned_resolves) = sell(amount);
		return (returned_eth, returned_resolves);
	}

	 
	function getMeOutOfHere() public {
		sellAllBonds();
		withdraw( resolveEarnings(msg.sender) );
	}

	 
	function fund() payable public returns(uint){
		uint bought;
		if (msg.value > 0.000001 ether) {
		  	contractBalance += msg.value;
			bought = buy();
		} else {
			revert();
		}
		return bought;
  	}

     
	function pricing(uint scale) public view returns (uint buyPrice, uint sellPrice, uint fee) {
		uint buy_eth = scaleFactor * getPriceForBonds( scale, true) / ( scaleFactor - fluxFee(scaleFactor) ) ;
        uint sell_eth = getPriceForBonds(scale, false);
        sell_eth -= fluxFee(sell_eth);
        return ( buy_eth, sell_eth, fluxFee(scale) );
    }

     
	function getPriceForBonds(uint256 bonds, bool upDown) public view returns (uint256 price) {
		uint reserveAmount = reserve();

		if(upDown){
			uint x = fixedExp((fixedLog(_totalSupply + bonds) - price_coeff) * crr_d/crr_n);
			return x - reserveAmount;
		}else{
			uint x = fixedExp((fixedLog(_totalSupply - bonds) - price_coeff) * crr_d/crr_n);
			return reserveAmount - x;
		}
	}

	 
	 
	 
	function resolveEarnings(address _owner) public view returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerResolve * resolveWeight[_owner]) - payouts[_owner]) / scaleFactor;
	}

	 
	function balance() internal view returns (uint256 amount) {
		 
		return contractBalance - msg.value;
	}
	event Buy( address indexed addr, uint256 spent, uint256 bonds, uint256 resolveTax);
	function buy() internal returns(uint){
		 
		if ( msg.value < 0.000001 ether )
			revert();

		 
		uint fee = fluxFee(msg.value);

		 
		uint numEther = msg.value - fee;
		buySum += numEther;

		 
		uint currentTime = NOW();
		avgFactor_ethSpent[msg.sender] += numEther;
		avgFactor_buyInTimeSum[msg.sender] += currentTime * scaleFactor * numEther;

		 
		uint createdBonds = getBondsForEther(numEther);

		 
		_totalSupply += createdBonds;

		 
		hodlBonds[msg.sender] += createdBonds;

		 
		uint resolveFee;
		if (_totalSupply > 0 && fee > 0) {
			resolveFee = fee * scaleFactor;

			 
			 
			uint rewardPerResolve = resolveFee / dissolvingResolves;

			 
			earningsPerResolve += rewardPerResolve;
		}
		emit Buy( msg.sender, msg.value, createdBonds, resolveFee);
		return createdBonds;
	}
	function NOW() public view returns(uint time){
		return now - genesis;
	}
	function avgHodl() public view returns(uint hodlTime){
		return avgFactor_releaseTimeSum / avgFactor_releaseWeight / scaleFactor;
	}
	function getReturnsForBonds(address addr, uint bondsReleased) public view returns(uint etherValue, uint mintedResolves, uint new_releaseTimeSum, uint new_releaseWeight, uint initialInput_ETH){
		uint output_ETH = getEtherForBonds(bondsReleased);
		uint input_ETH = avgFactor_ethSpent[addr] * bondsReleased / hodlBonds[addr];
		 
		 
		uint buyInTime = avgFactor_buyInTimeSum[addr] / avgFactor_ethSpent[addr];
		uint cashoutTime = NOW()*scaleFactor - buyInTime;
		uint releaseTimeSum = avgFactor_releaseTimeSum + cashoutTime*input_ETH/scaleFactor*buyInTime;
		uint releaseWeight = avgFactor_releaseWeight + input_ETH*buyInTime/scaleFactor;
		uint avgCashoutTime = releaseTimeSum/releaseWeight;
		return (output_ETH, input_ETH * cashoutTime / avgCashoutTime * input_ETH / output_ETH, releaseTimeSum, releaseWeight, input_ETH);
	}
	event Sell( address indexed addr, uint256 bondsSold, uint256 cashout, uint256 resolves, uint256 resolveTax, uint256 initialCash);
	function sell(uint256 amount) internal returns(uint eth, uint resolves){
	  	 
		uint numEthersBeforeFee;
		uint mintedResolves;
		uint releaseTimeSum;
		uint releaseWeight;
		uint initialInput_ETH;
		(numEthersBeforeFee,mintedResolves,releaseTimeSum,releaseWeight,initialInput_ETH) = getReturnsForBonds(msg.sender, amount);

		 
		resolveToken.mint(msg.sender, mintedResolves);

		 
		avgFactor_releaseTimeSum = releaseTimeSum;
		avgFactor_releaseWeight = releaseWeight;

		 
		avgFactor_ethSpent[msg.sender] -= initialInput_ETH;
		 
		avgFactor_buyInTimeSum[msg.sender] = avgFactor_buyInTimeSum[msg.sender] * (hodlBonds[msg.sender] - amount) / hodlBonds[msg.sender];
		
		 
	    uint fee = fluxFee(numEthersBeforeFee);

		 
	    uint numEthers = numEthersBeforeFee - fee;

	     
	    sellSum += initialInput_ETH;

		 
		_totalSupply -= amount;

	     
	    hodlBonds[msg.sender] -= amount;


		 
		uint resolveFee;
		if (_totalSupply > 0 && dissolvingResolves > 0){
			 
			resolveFee = fee * scaleFactor;

			 
			 
			uint rewardPerResolve = resolveFee / dissolvingResolves;

			 
			earningsPerResolve += rewardPerResolve;
		}
		
		 
		contractBalance -= numEthers;
		msg.sender.transfer(numEthers);
		emit Sell( msg.sender, amount, numEthers, mintedResolves, resolveFee, initialInput_ETH);
		return (numEthers, mintedResolves);
	}

	 
	function reserve() public view returns (uint256 amount) {
		return balance() -
			 ((uint256) ((int256) (earningsPerResolve * dissolvingResolves) - totalPayouts) / scaleFactor);
	}

	 
	 
	function getBondsForEther(uint256 ethervalue) public view returns (uint256 bonds) {
		uint new_totalSupply = fixedExp( fixedLog(reserve() + ethervalue ) * crr_n/crr_d + price_coeff);
		if (new_totalSupply < _totalSupply)
			return 0;
		else
			return new_totalSupply - _totalSupply;
	}

	 
	function calculateBondsFromReinvest(uint256 ethervalue, uint256 subvalue) public view returns (uint256 bondTokens) {
		return fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff)- _totalSupply;
	}

	 
	function getEtherForBonds(uint256 bondTokens) public view returns (uint256 ethervalue) {
		 
		uint reserveAmount = reserve();

		 
		if (bondTokens == _totalSupply)
			return reserveAmount;

		 
		 
		 
		 
		uint x = fixedExp((fixedLog(_totalSupply - bondTokens) - price_coeff) * crr_d/crr_n);
		if (x > reserveAmount)
			return 0;

		return reserveAmount - x;
	}

	 
	 
		int256  constant one        = 0x10000000000000000;
		uint256 constant sqrt2      = 0x16a09e667f3bcc908;
		uint256 constant sqrtdot5   = 0x0b504f333f9de6484;
		int256  constant ln2        = 0x0b17217f7d1cf79ac;
		int256  constant ln2_64dot5 = 0x2cb53f09f05cc627c8;
		int256  constant c1         = 0x1ffffffffff9dac9b;
		int256  constant c3         = 0x0aaaaaaac16877908;
		int256  constant c5         = 0x0666664e5e9fa0c99;
		int256  constant c7         = 0x049254026a7630acf;
		int256  constant c9         = 0x038bd75ed37753d68;
		int256  constant c11        = 0x03284a0c14610924f;

	 
	 
	 
	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > sqrt2) {
			a /= 2;
			scale++;
		}
		while (a <= sqrtdot5) {
			a *= 2;
			scale--;
		}
		int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
		int z = (s*s) / one;
		return scale * ln2 +
			(s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
				/one))/one))/one))/one))/one);
	}

	int256 constant c2 =  0x02aaaaaaaaa015db0;
	int256 constant c4 = -0x000b60b60808399d1;
	int256 constant c6 =  0x0000455956bccdd06;
	int256 constant c8 = -0x000001b893ad04b3a;

	 
	 
	 
	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
		a -= scale*ln2;
		int256 z = (a*a) / one;
		int256 R = ((int256)(2) * one) +
			(z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
		exp = (uint256) (((R + a) * one) / (R - a));
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
	}

	 
	 
	function () payable external {
		 
		if (msg.value > 0) {
			fund();
		} else {
			withdraw( resolveEarnings(msg.sender) );
		}
	}

	 
	event StakeResolves( address indexed addr, uint256 amountStaked, bytes _data );
	function tokenFallback(address from, uint value, bytes calldata _data) external{
		if(msg.sender == address(resolveToken) ){
			resolveWeight[from] += value;
			dissolvingResolves += value;

			 
			int payoutDiff  = (int256) (earningsPerResolve * value);

			 
			payouts[from] += payoutDiff;

			 
			totalPayouts += payoutDiff;
			emit StakeResolves(from, value, _data);
		}else{
			revert("no want");
		}
	}


	 
	 
	event Withdraw( address indexed addr, uint256 earnings, uint256 dissolve );
	function withdraw(uint amount) public returns(uint){
		 
		uint totalEarnings = resolveEarnings(msg.sender);
		require(amount <= totalEarnings, "the amount exceeds total earnings");
		uint oldWeight = resolveWeight[msg.sender];
		resolveWeight[msg.sender] = oldWeight * (totalEarnings - amount) / totalEarnings;
		uint weightDiff = oldWeight - resolveWeight[msg.sender];
		dissolved += weightDiff;
		dissolvingResolves -= weightDiff;

		 
		int resolvePayoutDiff  = (int256) (earningsPerResolve * weightDiff);

		payouts[msg.sender] += (int256) (amount * scaleFactor) - resolvePayoutDiff;

		 
		totalPayouts += (int256) (amount * scaleFactor) - resolvePayoutDiff;

		 
		contractBalance -= amount;
		msg.sender.transfer(amount);
		emit Withdraw( msg.sender, amount, weightDiff);
		return weightDiff;
	}
	event PullResolves( address indexed addr, uint256 pulledResolves, uint256 forfeiture);
	function pullResolves(uint amount) public{
		require(amount <= resolveWeight[msg.sender], "that amount is too large");
		 

		uint forfeitedEarnings  =  resolveEarnings(msg.sender)  * amount / resolveWeight[msg.sender] * scaleFactor;
		resolveWeight[msg.sender] -= amount;
		dissolvingResolves -= amount;
		 
		earningsPerResolve += forfeitedEarnings / dissolvingResolves;
		resolveToken.transfer(msg.sender, amount);
		emit PullResolves( msg.sender, amount, forfeitedEarnings / scaleFactor);
	}

	event BondTransfer(address from, address to, uint amount);
	function bondTransfer( address to, uint amount ) public{
		 
		address sender = msg.sender;
		uint totalBonds = hodlBonds[sender];
		require(amount <= totalBonds, "amount exceeds hodlBonds");
		uint ethSpent = avgFactor_ethSpent[sender] * amount / totalBonds;
		uint buyInTimeSum = avgFactor_buyInTimeSum[sender] * amount / totalBonds;
		avgFactor_ethSpent[sender] -= ethSpent;
		avgFactor_buyInTimeSum[sender] -= buyInTimeSum;
		hodlBonds[sender] -= amount;
		avgFactor_ethSpent[to] += ethSpent;
		avgFactor_buyInTimeSum[to] += buyInTimeSum;
		hodlBonds[to] += amount;
		emit BondTransfer(sender, to, amount);
	}
}

contract ERC223ReceivingContract{
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

contract ResolveToken{
	address pyramid;

	constructor(address _pyramid) public{
		pyramid = _pyramid;
	}

	modifier pyramidOnly{
	  require(msg.sender == pyramid);
	  _;
    }

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);

	event Mint(
		address indexed addr,
		uint256 amount
	);

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) approvals;

	string public name = "Resolve";
    string public symbol = "PoWHr";
    uint8 constant public decimals = 18;
	uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
	function mint(address _address, uint _value) public pyramidOnly(){
		balances[_address] += _value;
		_totalSupply += _value;
		emit Mint(_address, _value);
	}

	 
	function transfer(address _to, uint _value, bytes memory _data) public returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		if(isContract(_to)) {
			return transferToContract(_to, _value, _data);
		}else{
			return transferToAddress(_to, _value, _data);
		}
	}

	 
	 
	function transfer(address _to, uint _value) public returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		 
		 
		bytes memory empty;
		if(isContract(_to)){
			return transferToContract(_to, _value, empty);
		}else{
			return transferToAddress(_to, _value, empty);
		}
	}

	 
	function isContract(address _addr) public view returns (bool is_contract) {
		uint length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		if(length>0) {
			return true;
		}else {
			return false;
		}
	}

	 
	function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool success) {
		moveTokens(msg.sender,_to,_value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	 
	function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success) {
		moveTokens(msg.sender, _to, _value);
		ERC223ReceivingContract reciever = ERC223ReceivingContract(_to);
		reciever.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function moveTokens(address _from, address _to, uint _amount) private{
		balances[_from] -= _amount;
		balances[_to] += _amount;
	}

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool){
        require(approvals[src][msg.sender] >=  wad, "That amount is not approved");
        require(balances[src] >=  wad, "That amount is not available from this wallet");
        if (src != msg.sender) {
            approvals[src][msg.sender] -=  wad;
        }
		moveTokens(src,dst,wad);

        bytes memory empty;
        emit Transfer(src, dst, wad, empty);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    event Approval(address indexed src, address indexed guy, uint wad);
}
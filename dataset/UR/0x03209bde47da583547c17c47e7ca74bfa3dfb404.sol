 

pragma solidity ^ 0.4 .11;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        } else {
            _;
        }
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }


}

 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns(uint256);

    function transferFrom(address from, address to, uint256 value);

    function approve(address spender, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath
    for uint256;
    mapping(address => uint256) balances;

	 
    function transfer(address _to, uint256 _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
	
	 
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;
	
	 
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

	   
    function approve(address _spender, uint256 _value) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

	 
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintStarted();

    bool public mintingFinished = true;
    bool public goalReached = false;
    uint public mintingStartTime = 0;
    uint public maxMintingTime = 30 days;
    uint public mintingGoal = 500 ether;

    address public titsTokenAuthor = 0x189891d02445D87e70d515fD2159416f023B0087;

	 
    function donateAuthor() payable {
        titsTokenAuthor.transfer(msg.value);
    }

    bool public alreadyMintedOnce = false;

    modifier mintingClosed() {
        if (mintingFinished == false || alreadyMintedOnce == false) revert();
        _;
    }

    modifier notMintedYet() {
        if (alreadyMintedOnce == true) revert();
        _;
    }

    
	 
    function fastBuyBonus() private returns(uint) {
        uint period = now - mintingStartTime;
        if (period < 1 days) {
            return 5000;
        }
        if (period < 2 days) {
            return 4000;
        }
        if (period < 3 days) {
            return 3000;
        }
        if (period < 7 days) {
            return 2600;
        }
        if (period < 10 days) {
            return 2400;
        }
        if (period < 12 days) {
            return 2200;
        }
        if (period < 14 days) {
            return 2000;
        }
        if (period < 17 days) {
            return 1800;
        }
        if (period < 19 days) {
            return 1600;
        }
        if (period < 21 days) {
            return 1400;
        }
        if (period < 23 days) {
            return 1200;
        }
        return 1000;
    }

	 
    function buy() payable returns(bool) {
        if (mintingFinished) {
            revert();
        }

        uint _amount = 0;
        _amount = msg.value * fastBuyBonus();
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        balances[owner] = balances[owner].add(_amount / 85 * 15);  
        return true;
    }

	 
    function startMinting() onlyOwner returns(bool) {
        mintingStartTime = now;
        if (alreadyMintedOnce) {
            revert();
        }
        alreadyMintedOnce = true;
        mintingFinished = false;
        MintStarted();
        return true;
    }

	 
    function finishMinting() returns(bool) {
        if (mintingFinished == false) {
            if (now - mintingStartTime > maxMintingTime) {
                mintingFinished = true;
                MintFinished();
                goalReached = (this.balance > mintingGoal);
                return true;
            }
        }
        return false;
    }

	 
    function refund() returns(bool) {
        if (mintingFinished == true && goalReached == false && alreadyMintedOnce == true) {
            uint valueOfAssets = this.balance.mul(balances[msg.sender]).div(totalSupply.sub(balances[owner]));
            totalSupply = totalSupply.sub(balances[msg.sender]);
            balances[msg.sender] = 0;
            msg.sender.transfer(valueOfAssets);
			return true;
        }
		return false;
    }
 
 
	 
    function destroyUselessContract() onlyOwner notMintedYet {
        selfdestruct(owner);
    }
}

contract TitsToken is MintableToken {
    string public name = "Truth In The Sourcecode";
    string public symbol = "TITS";
    uint public decimals = 18;
    uint public voitingStartTime;
    address public votedAddress;
    uint public votedYes = 1;
    uint public votedNo = 0;
    event VoteOnTransfer(address indexed beneficiaryContract);
    event RogisterToVoteOnTransfer(address indexed beneficiaryContract);
    event VotingEnded(address indexed beneficiaryContract, bool result);

    uint public constant VOTING_PREPARE_TIMESPAN = 7 days;
    uint public constant VOTING_TIMESPAN =  7 days;
    uint public failedVotingCount = 0;
    bool public isVoting = false;
    bool public isVotingPrepare = false;

    address public beneficiaryContract = 0;

    mapping(address => uint256) votesAvailable;
    address[] public voters;
    uint votersCount = 0;

	 
    modifier votingLong() {
        if (now - voitingStartTime < VOTING_TIMESPAN) revert();
        _;
    }

	 
    modifier votingPrepareLong() {
        if (now - voitingStartTime < VOTING_PREPARE_TIMESPAN) revert();
        _;
    }

	 
    modifier votingInProgress() {
        if (isVoting == false) revert();
        _;
    }

	 
    modifier votingPrepareInProgress() {
        if (isVotingPrepare == false) revert();
        _;
    }

	 
    function sendToBeneficiaryContract()  {
        if (beneficiaryContract != 0) {
            beneficiaryContract.transfer(this.balance);
        } else {
            revert();
        }
    }
		
	 
	function registerVotingPrepareFailure() mintingClosed{
		if(now-mintingStartTime>(2+failedVotingCount)*maxMintingTime ){
			failedVotingCount=failedVotingCount+1;
            if (failedVotingCount == 10) {
                goalReached = false;
            }
		}
	}

	 
    function startVotingPrepare(address votedAddressArg) mintingClosed onlyOwner{
        isVoting = false;
        RogisterToVoteOnTransfer(votedAddressArg);
        votedAddress = votedAddressArg;
        voitingStartTime = now;
        isVotingPrepare = true;
        for (uint i = 0; i < voters.length; i++) {
            delete voters[i];
        }
        delete voters;
        votersCount = 0;
    }

	 
    function registerForVoting() payable votingPrepareInProgress {
        if (msg.value >= 10 finney) {
            voters.push(msg.sender);
            votersCount = votersCount + 1;
        }
		else{
			revert();
		}
    }

	 
    function startVoting() votingPrepareInProgress votingPrepareLong {
        VoteOnTransfer(votedAddress);
        for (uint i = 0; i < votersCount; i++) {
            votesAvailable[voters[i]] = balanceOf(voters[i]);
        }
        isVoting = true;
        voitingStartTime = now;
        isVotingPrepare = false;
        votersCount = 0;
    }

	 
    function closeVoring() votingInProgress votingLong {
        VotingEnded(votedAddress, votedYes > votedNo);
        isVoting = false;
        isVotingPrepare = false;
        if (votedYes > votedNo) {
            beneficiaryContract = votedAddress;
        } else {
            failedVotingCount = failedVotingCount + 1;
            if (failedVotingCount == 10) {
                goalReached = false;
            }
        }
    }

	 
    function vote(bool isVoteYes) payable {

        if (msg.value >= 10 finney) {
            var votes = votesAvailable[msg.sender];
            votesAvailable[msg.sender] = 0;
            if (isVoteYes) {
                votedYes.add(votes);
            } else {
                votedNo.add(votes);
            }
        }
		else{
			revert();
		}
    }
}
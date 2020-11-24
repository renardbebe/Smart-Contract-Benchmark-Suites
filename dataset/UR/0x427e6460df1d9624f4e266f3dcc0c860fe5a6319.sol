 

pragma solidity ^0.4.15;

 

contract Bounty {
     
    bool public bounty_paid = false;
     
    uint256 public count_donors = 0;
     
    mapping (address => uint256) public balances;
     
    mapping (address => bool) public has_donated;
     
    mapping (address => bool) public has_voted;

    address public proposed_beneficiary = 0x0;
    uint256 public votes_for = 0;
    uint256 public votes_against = 0;

    bytes32 hash_pwd = 0x1a78e83f94c1bc28c54cfed1fe337e04c31732614ec822978d804283ef6a60c3;

    modifier onlyDonor {
        require(!bounty_paid);
        require(has_donated[msg.sender]);
         
        _;
    }


     
    function payout(string _password) {
        require(keccak256(_password) == hash_pwd);
        require(!bounty_paid);
        require(proposed_beneficiary != 0x0);
         
        require(votes_for > votes_against);
         
        require(votes_for+votes_against > count_donors*8/10);
        bounty_paid = true;
        proposed_beneficiary.transfer(this.balance);

    }

    function propose_beneficiary(address _proposed) onlyDonor {
         
        proposed_beneficiary = _proposed;
         
        votes_for = 0;
        votes_against = 0;

    }

     
     
    function vote_beneficiary(string _vote) onlyDonor {
        require(!has_voted[msg.sender]);
        require(proposed_beneficiary != 0x0);
        if (keccak256(_vote) == keccak256("yes")) {
            votes_for += 1;
            has_voted[msg.sender] = true;
        }
        if (keccak256(_vote) == keccak256("no")) {
            votes_against += 1;
            has_voted[msg.sender] = true;
        }
    }

     
    function refund() onlyDonor {
         
        has_donated[msg.sender] = false;
        count_donors -= 1;

         
        uint256 eth_to_withdraw = balances[msg.sender];
        
         
        balances[msg.sender] = 0;
        
         
        msg.sender.transfer(eth_to_withdraw);
    }

     
    function () payable {
         
        require(!bounty_paid);
         
        require(count_donors < 51);
         
        require(msg.value >= 0.1 ether);
         
        if (!has_donated[msg.sender]) {
            has_donated[msg.sender] = true;
            count_donors += 1;
        } 
        balances[msg.sender] += msg.value;
    }
}
 

pragma solidity ^0.4.12;

contract Leaderboard {
     
    address owner;
     
    uint256 public minBid;
     
    uint public maxLeaders;
    
     
    uint public numLeaders;
    address public head;
    address public tail;
    mapping (address => Leader) public leaders;
    
    struct Leader {
         
        uint256 amount;
        string url;
        string img_url;
        
         
        address next;
        address previous;
    }
    
    
     
    function Leaderboard() {
        owner = msg.sender;
        minBid = 0.001 ether;
        numLeaders = 0;
        maxLeaders = 10;
    }
    
    
     
    function () payable {
         
        require(msg.value >= minBid);
        
         
        uint256 remainder  = msg.value % minBid;
        uint256 bid_amount = msg.value - remainder;
        
         
        require(!((numLeaders == maxLeaders) && (bid_amount <= leaders[tail].amount)));
        
         
        Leader memory leader = popLeader(msg.sender);
        
         
        leader.amount += bid_amount;
        
         
        insertLeader(leader);
        
         
        if (numLeaders > maxLeaders) {
            dropLast();
        }
        
         
        if (remainder > 0) msg.sender.transfer(remainder);
    }
    
    
     
    function setUrls(string url, string img_url) {
        var leader = leaders[msg.sender];
        
        require(leader.amount > 0);
        
         
        bytes memory tmp_url = bytes(url);
        if (tmp_url.length != 0) {
             
            leader.url = url;
        }
        
         
        bytes memory tmp_img_url = bytes(img_url);
        if (tmp_img_url.length != 0) {
             
            leader.img_url = img_url;
        }
    }
    
    
     
    function resetUrls(bool url, bool img_url) {
        var leader = leaders[msg.sender];
        
        require(leader.amount > 0);
        
         
        if (url) leader.url = "";
        if (img_url) leader.img_url = "";
    }
    
    
     
    function getLeader(address key) constant returns (uint amount, string url, string img_url, address next) {
        amount  = leaders[key].amount;
        url     = leaders[key].url;
        img_url = leaders[key].img_url;
        next    = leaders[key].next;
    }
    
    
     
    function popLeader(address key) internal returns (Leader leader) {
        leader = leaders[key];
        
         
        if (leader.amount == 0) {
            return leader;
        }
        
        if (numLeaders == 1) {
            tail = 0x0;
            head = 0x0;
        } else if (key == head) {
            head = leader.next;
            leaders[head].previous = 0x0;
        } else if (key == tail) {
            tail = leader.previous;
            leaders[tail].next = 0x0;
        } else {
            leaders[leader.previous].next = leader.next;
            leaders[leader.next].previous = leader.previous;
        }
        
        numLeaders--;
        return leader;
    }
    
    
     
    function insertLeader(Leader leader) internal {
        if (numLeaders == 0) {
            head = msg.sender;
            tail = msg.sender;
        } else if (leader.amount <= leaders[tail].amount) {
            leaders[tail].next = msg.sender;
            tail = msg.sender;
        } else if (leader.amount > leaders[head].amount) {
            leader.next = head;
            leaders[head].previous = msg.sender;
            head = msg.sender;
        } else {
            var current_addr = head;
            var current = leaders[current_addr];
            
            while (current.amount > 0) {
                if (leader.amount > current.amount) {
                    leader.next = current_addr;
                    leader.previous = current.previous;
                    current.previous = msg.sender;
                    leaders[current.previous].next = msg.sender;
                    break;
                }
                
                current_addr = current.next;
                current = leaders[current_addr];
            }
        }
        
        leaders[msg.sender] = leader;
        numLeaders++;
    }
    
    
     
    function dropLast() internal {
         
        address leader_addr = tail;
        var leader = popLeader(leader_addr);
        
        uint256 refund_amount = leader.amount;
        
         
        delete leader;
        
         
        leader_addr.transfer(refund_amount);
    }

    
     
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }


     
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
    
     
    function setMaxLeaders(uint newMax) onlyOwner {
        maxLeaders = newMax;
    }
}
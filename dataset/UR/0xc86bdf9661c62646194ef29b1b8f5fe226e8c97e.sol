 

pragma solidity ^0.4.13;

contract EtherShare {
    
    uint public count;
    address[] public link;  

    struct oneShare {
        address sender;
        string nickname;
        uint timestamp;
        bool AllowUpdated;
        string content;
    }
    mapping(uint => oneShare[]) public allShare;

    event EVENT(uint ShareID, uint ReplyID);

    function EtherShare() public {
        NewShare("Peilin Zheng", false, "Hello, EtherShare!");   
    }

    function NewShare(string nickname, bool AllowUpdated, string content) public {
        allShare[count].push(oneShare(msg.sender, nickname, now, AllowUpdated, content));  
        EVENT(count,0);
        count++;
    }

    function ReplyShare(uint ShareID, string nickname, bool AllowUpdated, string content) public {
        require(ShareID<count);  
        allShare[ShareID].push(oneShare(msg.sender, nickname, now, AllowUpdated, content));
        EVENT(ShareID,allShare[ShareID].length-1);
    }

    function Update(uint ShareID, uint ReplyID, string content) public {
        require(msg.sender==allShare[ShareID][ReplyID].sender && allShare[ShareID][ReplyID].AllowUpdated);   
        allShare[ShareID][ReplyID].content = content;
        allShare[ShareID][ReplyID].timestamp = now;
        EVENT(ShareID,ReplyID);
    }
}
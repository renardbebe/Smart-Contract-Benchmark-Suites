 

contract mortal {
     
    address owner;

     
    function mortal() { owner = msg.sender; }

     
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

contract Videos is mortal {

    uint public numVideos;

    struct  Video {
        string videoURL;
        string team;
        uint amount;
    }
    mapping (uint => Video) public videos;
    
    function Videos(){
        numVideos=0;

    }
    
    function submitVideo(string videoURL, string team) returns (uint videoID)
    {
        videoID = numVideos;
        videos[videoID] = Video(videoURL, team, msg.value);
        numVideos = numVideos+1;
    }
    
        function vote(uint videoID)
    {
        uint payout;
        videos[videoID].amount=videos[videoID].amount+msg.value;
        payout = msg.value / ((block.number % 10)+1);
	    if(payout > 0){
	        msg.sender.send(payout);
	    }
    }
  
}
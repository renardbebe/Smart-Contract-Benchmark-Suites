 

pragma solidity ^0.4.11;

 

 
contract RatingStore {

    struct Score {
        bool exists;
        int cumulativeScore;
        uint totalRatings;
    }

    bool internal debug;
    mapping (address => Score) internal scores;
     
    address internal manager;
     
    address internal controller;

     
    event Debug(string message);

     
    modifier restricted() { 
        require(msg.sender == manager || tx.origin == manager || msg.sender == controller);
        _; 
    }

     
    modifier onlyBy(address by) { 
        require(msg.sender == by);
        _; 
    }

     
    function RatingStore(address _manager, address _controller) {
        manager = _manager;
        controller = _controller;
        debug = false;
    }

     
    function set(address target, int cumulative, uint total) external restricted {
        if (!scores[target].exists) {
            scores[target] = Score(true, 0, 0);
        }
        scores[target].cumulativeScore = cumulative;
        scores[target].totalRatings = total;
    }

     
    function add(address target, int wScore) external restricted {
        if (!scores[target].exists) {
            scores[target] = Score(true, 0, 0);
        }
        scores[target].cumulativeScore += wScore;
        scores[target].totalRatings += 1;
    }

     
    function get(address target) external constant returns (int, uint) {
        if (scores[target].exists == true) {
            return (scores[target].cumulativeScore, scores[target].totalRatings);
        } else {
            return (0,0);
        }
    }

     
    function reset(address target) external onlyBy(manager) {
        scores[target] = Score(true, 0,0);
    }

     
    function getManager() external constant returns (address) {
        return manager;
    }

     
    function setManager(address newManager) external onlyBy(manager) {
        manager = newManager;
    }

     
    function getController() external constant returns (address) {
        return controller;
    }

     
    function setController(address newController) external onlyBy(manager) {
        controller = newController;
    }

     
    function getDebug() external constant returns (bool) {
        return debug;
    }

     
    function setDebug(bool _debug) external onlyBy(manager) {
        debug = _debug;
    }

}

 
contract Etherep {

    bool internal debug;
    address internal manager;
    uint internal fee;
    address internal storageAddress;
    uint internal waitTime;
    mapping (address => uint) internal lastRating;

     
    event Error(
        address sender,
        string message
    );
    event Debug(string message);
    event DebugInt(int message);
    event DebugUint(uint message);
    event Rating(
        address by, 
        address who, 
        int rating
    );
    event FeeChanged(uint f);
    event DelayChanged(uint d);

     
    modifier onlyBy(address by) { 
        require(msg.sender == by);
        _; 
    }

     
    modifier delay() {
        if (debug == false && lastRating[msg.sender] > now - waitTime) {
            Error(msg.sender, "Rating too often");
            revert();
        }
        _;
    }

     
    modifier requireFee() {
        require(msg.value >= fee);
        _;
    }

     
    function Etherep(address _manager, uint _fee, address _storageAddress, uint _wait) {
        manager = _manager;
        fee = _fee;
        storageAddress = _storageAddress;
        waitTime = _wait;
        debug = false;
    }

     
    function setDebug(bool d) external onlyBy(manager) {
        debug = d;
    }

     
    function getDebug() external constant returns (bool) {
        return debug;
    }

     
    function setFee(uint newFee) external onlyBy(manager) {
        fee = newFee;
        FeeChanged(fee);
    }

     
    function getFee() external constant returns (uint) {
        return fee;
    }

     
    function setDelay(uint _delay) external onlyBy(manager) {
        waitTime = _delay;
        DelayChanged(waitTime);
    }

     
    function getDelay() external constant returns (uint) {
        return waitTime;
    }

     
    function setManager(address who) external onlyBy(manager) {
        manager = who;
    }

     
    function getManager() external constant returns (address) {
        return manager;
    }

     
    function drain() external onlyBy(manager) {
        require(this.balance > 0);
        manager.transfer(this.balance);
    }

     
    function rate(address who, int rating) external payable delay requireFee {

        require(rating <= 5 && rating >= -5);
        require(who != msg.sender);

        RatingStore store = RatingStore(storageAddress);
        
         
        int weight = 0;

         
        int multiplier = 100;

         
        int absRating = rating;
        if (absRating < 0) {
            absRating = -rating;
        }

         
        int senderScore;
        uint senderRatings;
        int senderCumulative = 0;
        (senderScore, senderRatings) = store.get(msg.sender);

         
        if (senderScore != 0) {
            senderCumulative = (senderScore / (int(senderRatings) * 100)) * 100;
        }

         
        if (senderCumulative > 0) {
            weight = (((senderCumulative / 5) * absRating) / 10) + multiplier;
        }
         
        else {
            weight = multiplier;
        }
        
         
        int workRating = rating * weight;

         
        lastRating[msg.sender] = now;

        Rating(msg.sender, who, workRating);

         
        store.add(who, workRating);

    }

     
    function getScore(address who) external constant returns (int score) {

        RatingStore store = RatingStore(storageAddress);
        
        int cumulative;
        uint ratings;
        (cumulative, ratings) = store.get(who);
        
         
         
        score = cumulative / int(ratings);

    }

     
    function getScoreAndCount(address who) external constant returns (int score, uint ratings) {

        RatingStore store = RatingStore(storageAddress);
        
        int cumulative;
        (cumulative, ratings) = store.get(who);
        
         
         
        score = cumulative / int(ratings);

    }

}
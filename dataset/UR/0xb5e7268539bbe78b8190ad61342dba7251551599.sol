 

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
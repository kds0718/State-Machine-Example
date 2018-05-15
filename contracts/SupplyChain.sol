pragma solidity ^0.4.23; 

/* This contract is to model a production order of a widget to be used in conjuction with
Token Foundry's state machine contract design */

import "@tokenfoundry/state-machine/contracts/TimedStateMachine.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract SupplyChain is TimedStateMachine, Ownable {

    using SafeMath for uint256;

    uint256 public startTime; 
    uint256 public productionEndTime; 
    bool public urgentOrder; 
    bool public qualityChecked; 
    bool public inRework; 
    bool public shipped; 

    // State machine states
    bytes32 private constant SETUP = 'setup';
    bytes32 private constant PRODUCTION = 'production';
    bytes32 private constant QUALITY = 'quality';
    bytes32 private constant SHIPPING = 'shipping';
    bytes32[] public states = [SETUP, PRODUCTION, QUALITY,SHIPPING];

    constructor() {
        setStates(states);
        allowFunction(SETUP, this.setStartTime.selector);
        allowFunction(PRODUCTION, this.endProduction.selector);
        allowFunction(PRODUCTION, this.startProduction.selector);
        allowFunction(QUALITY, this.recordQualityCheck.selector);
        allowFunction(SHIPPING, this.recordShipment.selector);

        // End the sale when the cap is reached
        addStartCondition(SHIPPING, wasQualityOk);

        // Set the onSaleEnded callback (will be called when the sale ends)
        addCallback(QUALITY, markUrgent);

    }

    function setStartTime(uint256 time) public checkAllowed onlyOwner {
        setStateStartTime(PRODUCTION, block.timestamp+time);
    }

    function startProduction() public checkAllowed {
        startTime = now;
    }

    function endProduction() public checkAllowed {
        require(now > startTime);
        productionEndTime = now; 
        
        goToNextState();
    }

    function markUrgent() internal {
        //If the product was in production for more than 5 days, mark it as urgent
        if (productionEndTime.sub(startTime) > 432000) {
            urgentOrder = true;
        } else {
            urgentOrder = false;
        }
    }

    function recordQualityCheck(bool pass) public checkAllowed {
        qualityChecked = pass;  
        goToNextState();
    }

    function wasQualityOk(bytes32) internal returns (bool) {
        if (!qualityChecked) {
            inRework = true;
        } else {
            inRework = false; 
        }
        return qualityChecked;
    }

    function recordShipment() public checkAllowed {
        shipped = true; 
    }

}
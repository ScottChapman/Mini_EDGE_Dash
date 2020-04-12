class SimpleKalmanFilter {
	hidden var err_measure = 0.0;	//error of the measure
	hidden var err_estimate = 0.0;	//error of the estimation. Updated in real time
	hidden var qo = 0.0;			//Maximum Process noise
	hidden var q = 0.0;				//Process noise
	hidden var current_estimate = 0.0;
	hidden var last_estimate = 0.0;
	hidden var kalman_gain = 0.0;

	function initialize(mea_e, est_e, _qo) {
		err_measure = mea_e;
		err_estimate = est_e;
		qo = _qo;
		q = _qo;
	}

	function updateEstimate(mea) {
		kalman_gain = err_estimate / (err_estimate + err_measure);
		current_estimate = last_estimate + kalman_gain * (mea - last_estimate);
		err_estimate = (1.0 - kalman_gain) * err_estimate + abs(last_estimate - current_estimate) * q;
		updateProcessNoise();
		last_estimate = current_estimate;
		return current_estimate;
	}

	function setInitialState(initial) {last_estimate = initial;}

	function getLastEstimate() {return last_estimate;}

	function updateProcessNoise() {
		//Modify q according to process variation
		//Make q=qo for a constant process noise
		
		var a = abs(last_estimate - current_estimate);
		q = qo / (1 + a * a);
	}

	function abs(value) {
		if(value < 0) {value = -value;}
		return (value);
	}
}
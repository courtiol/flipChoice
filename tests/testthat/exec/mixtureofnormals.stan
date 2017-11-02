functions {
    vector completeTheta(vector theta_raw, int A, int V, int[] V_attribute)
    {
        vector[V] theta;
        int variable_i = 1;
        int raw_variable_i = 1;
        for (i in 1:A)
        {
            if (V_attribute[i] > 1)
            {
                int v = V_attribute[i];
                for (j in 2:v)
                    theta[variable_i + j - 1] = theta_raw[raw_variable_i + j - 2];
                theta[variable_i] = -sum(theta_raw[raw_variable_i:(raw_variable_i + v - 2)]);
                variable_i = variable_i + v;
                raw_variable_i = raw_variable_i + v - 1;
            }
            else
            {
                theta[variable_i] = theta_raw[raw_variable_i];
                variable_i = variable_i + 1;
                raw_variable_i = raw_variable_i + 1;
            }
        }
        return theta;
    }
}

data {
    int<lower=2> C; // Number of alternatives (choices) in each question
    int<lower=1> R; // Number of respondents
    int<lower=1> S; // Number of questions per respondent
    int<lower=1> P; // Number of classes
    int<lower=1> A; // Number of attributes
    int<lower=1> V; // Number of variables
    int<lower=1> V_raw; // Number of raw variables
    int<lower=1> V_attribute[A]; // Number of variables in each attribute
    int<lower=1,upper=C> Y[R, S]; // choices
    matrix[C, V] X[R, S]; // matrix of attributes for each obs
    vector[V_raw] prior_sd; // Prior sd for theta_raw
}

parameters {
    vector[V_raw] theta_raw[P];
    cholesky_factor_corr[V] L_omega[P];
    vector<lower=0, upper=pi()/2>[V] sigma_unif[P];
    vector[V] standard_normal[R, P];
    simplex[P] class_weights;
}

transformed parameters {
    vector<lower=0>[V] sigma[P];
    matrix[V, V] L_sigma[P];
    vector[V] theta[P]; // sums to zero
    vector[V] beta[R, P];
    vector[P] posterior_prob[R];

    for (p in 1:P)
    {
        sigma[p] = 2.5 * tan(sigma_unif[p]);
        L_sigma[p] = diag_pre_multiply(sigma[p], L_omega[p]);

        theta[p] = completeTheta(theta_raw[p], A, V, V_attribute);

        for (r in 1:R)
            beta[r, p] = theta[p] + L_sigma[p] * standard_normal[r, p];
    }

    for (r in 1:R)
    {
        for (p in 1:P)
        {
            real prob = log(class_weights[p]);
            for (s in 1:S)
                prob = prob + categorical_logit_lpmf(Y[r, s] | X[r, s] * beta[r, p]);
            posterior_prob[r, p] = prob;
        }
    }
}

model {
    for (p in 1:P)
    {
        for (v in 1:V_raw)
            theta_raw[p, v] ~ normal(0, prior_sd[v]);
        L_omega[p] ~ lkj_corr_cholesky(4);
        for (r in 1:R)
            standard_normal[r, p] ~ normal(0, 1);
    }

    //likelihood
    for (r in 1:R)
        target += log_sum_exp(posterior_prob[r]);
}